//
//  OrganizeTokensDragAndDropController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt

protocol OrganizeTokensDragAndDropControllerDataSource: AnyObject {
    func numberOfSections(
        for controller: OrganizeTokensDragAndDropController
    ) -> Int

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfRowsInSection section: Int
    ) -> Int

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: IndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewIdentifierForItemAt indexPath: IndexPath
    ) -> AnyHashable
}

final class OrganizeTokensDragAndDropController: ObservableObject {
    weak var dataSource: OrganizeTokensDragAndDropControllerDataSource?

    private(set) var autoScrollStatus: OrganizeTokensDragAndDropControllerAutoScrollStatus = .inactive

    private(set) lazy var autoScrollTargetPublisher: some Publisher<AnyHashable, Never> = autoScrollStartSubject
        .withWeakCaptureOf(self)
        .flatMapLatest { controller, direction in
            // The first item from `additionalAutoScrollTargets` is emitted immediately
            // to get rid of delays between ticks of two separate timers
            let additionalAutoScrollTargets = controller.additionalAutoScrollTargets(scrollDirection: direction)
            let additionalAutoScrollTargetsPublisher = Timer
                .publish(every: controller.autoScrollFrequency, on: .main, in: .common)
                .autoconnect()
                .zip(additionalAutoScrollTargets.dropFirst(1).publisher)
                .map(\.1)
                .prepend(additionalAutoScrollTargets.prefix(1))

            return Timer
                .publish(every: controller.autoScrollFrequency, on: .main, in: .common)
                .autoconnect()
                .withLatestFrom(controller._contentOffsetSubject, controller._viewportSizeSubject)
                .withWeakCaptureOf(controller)
                .map { input -> AnyHashable? in
                    let (controller, (contentOffset, viewportSize)) = input
                    let scrollTargetIndexPath = controller.indexPathForAutoScrollTarget(
                        direction: direction,
                        contentOffset: contentOffset,
                        viewportSize: viewportSize
                    )
                    return scrollTargetIndexPath.flatMap { indexPath in
                        controller.dataSource?.controller(controller, listViewIdentifierForItemAt: indexPath)
                    }
                }
                .prefix { $0 != nil }
                .compactMap { $0 }
                .append(additionalAutoScrollTargetsPublisher)
                .removeDuplicates()
                .prefix(untilOutputFrom: controller.autoScrollStopSubject)
        }

    var viewportSizeSubject: some Subject<CGSize, Never> { _viewportSizeSubject }
    private let _viewportSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    private var itemsFrames: [IndexPath: CGRect] = [:]

    private let autoScrollStartSubject = PassthroughSubject<OrganizeTokensDragAndDropControllerAutoScrollDirection, Never>()
    private let autoScrollStopSubject = PassthroughSubject<Void, Never>()

    private let autoScrollFrequency: TimeInterval
    private let destinationItemSelectionThresholdRatio: Double

    private let topEdgeAdditionalAutoScrollTargets: [AnyHashable]
    private let bottomEdgeAdditionalAutoScrollTargets: [AnyHashable]

    private lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    init(
        autoScrollFrequency: TimeInterval,
        destinationItemSelectionThresholdRatio: Double,
        topEdgeAdditionalAutoScrollTargets: [AnyHashable] = [],
        bottomEdgeAdditionalAutoScrollTargets: [AnyHashable] = []
    ) {
        self.autoScrollFrequency = autoScrollFrequency
        self.destinationItemSelectionThresholdRatio = destinationItemSelectionThresholdRatio
        self.topEdgeAdditionalAutoScrollTargets = topEdgeAdditionalAutoScrollTargets
        self.bottomEdgeAdditionalAutoScrollTargets = bottomEdgeAdditionalAutoScrollTargets
    }

    func onDragPrepare() {
        selectionFeedbackGenerator.prepare()
    }

    func onDragStart() {
        selectionFeedbackGenerator.selectionChanged()
        impactFeedbackGenerator.prepare()
    }

    func onItemsMove() {
        impactFeedbackGenerator.impactOccurred()
    }

    func saveFrame(_ frame: CGRect, forItemAt indexPath: IndexPath) {
        itemsFrames[indexPath] = frame
    }

    func frame(forItemAt indexPath: IndexPath?) -> CGRect? {
        indexPath.flatMap { itemsFrames[$0] }
    }

    /// - Warning: O(N) time complexity.
    func indexPath(for location: CGPoint) -> IndexPath? {
        return itemsFrames
            .first { isIndexPathValid($0.key) && $0.value.contains(location) }
            .map(\.key)
    }

    func updatedDestinationIndexPath(
        source sourceIndexPath: IndexPath,
        currentDestination currentDestinationIndexPath: IndexPath,
        translationValue: CGSize
    ) -> IndexPath? {
        guard let dataSource = dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return nil
        }
        guard var draggedItemFrame = frame(forItemAt: sourceIndexPath) else {
            return nil
        }

        draggedItemFrame.origin.y += translationValue.height
        let neighboringIndexPaths: [IndexPath]

        switch dataSource.controller(self, listViewKindForItemAt: sourceIndexPath) {
        case .cell:
            neighboringIndexPaths = neighboringItemsIndexPaths(
                forItemAt: currentDestinationIndexPath,
                dataSource: dataSource
            )
        case .sectionHeader:
            neighboringIndexPaths = neighboringSectionsIndexPaths(
                forSectionAt: currentDestinationIndexPath,
                dataSource: dataSource
            )
        }

        return neighboringIndexPaths
            .first { neighboringIndexPath in
                guard let neighboringItemFrame = frame(forItemAt: neighboringIndexPath) else {
                    return false
                }

                let intersection = draggedItemFrame.intersection(neighboringItemFrame)

                return !intersection.isNull && intersection.height > neighboringItemFrame.height
                    * destinationItemSelectionThresholdRatio
            }
    }

    func startAutoScrolling(direction: OrganizeTokensDragAndDropControllerAutoScrollDirection) {
        guard !autoScrollStatus.isActive else { return }

        autoScrollStatus = .active(direction: direction)
        autoScrollStartSubject.send(direction)
    }

    func stopAutoScrolling() {
        guard autoScrollStatus.isActive else { return }

        autoScrollStopSubject.send()
        autoScrollStatus = .inactive
    }

    private func neighboringItemsIndexPaths(
        forItemAt indexPath: IndexPath,
        dataSource: OrganizeTokensDragAndDropControllerDataSource
    ) -> [IndexPath] {
        var neighboringItemsIndexPaths: [IndexPath] = []

        if indexPath.item > 0 {
            neighboringItemsIndexPaths.append(
                IndexPath(item: indexPath.item - 1, section: indexPath.section)
            )
        }

        let numberOfRowsInSection = dataSource.controller(self, numberOfRowsInSection: indexPath.section)
        if indexPath.item < numberOfRowsInSection - 1 {
            neighboringItemsIndexPaths.append(
                IndexPath(item: indexPath.item + 1, section: indexPath.section)
            )
        }

        return neighboringItemsIndexPaths
    }

    private func neighboringSectionsIndexPaths(
        forSectionAt indexPath: IndexPath,
        dataSource: OrganizeTokensDragAndDropControllerDataSource
    ) -> [IndexPath] {
        var neighboringSectionsIndexPaths: [IndexPath] = []

        if indexPath.section > 0 {
            neighboringSectionsIndexPaths.append(
                IndexPath(item: indexPath.item, section: indexPath.section - 1)
            )
        }

        let numberOfSections = dataSource.numberOfSections(for: self)
        if indexPath.section < numberOfSections - 1 {
            neighboringSectionsIndexPaths.append(
                IndexPath(item: indexPath.item, section: indexPath.section + 1)
            )
        }

        return neighboringSectionsIndexPaths
    }

    // Maybe not so memory-efficient, but definitely safer than manual clearing of `itemsFrames` cache
    private func isIndexPathValid(_ indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return false
        }

        let isSectionValid = 0 ..< dataSource.numberOfSections(for: self) ~= indexPath.section
        let listViewKind = dataSource.controller(self, listViewKindForItemAt: indexPath)

        switch listViewKind {
        case .cell where isSectionValid:
            let numberOfRowsInSection = dataSource.controller(self, numberOfRowsInSection: indexPath.section)
            return 0 ..< numberOfRowsInSection ~= indexPath.item
        case .cell, .sectionHeader:
            return isSectionValid
        }
    }

    /// - Warning: O(N) time complexity.
    private func indexPathForAutoScrollTarget(
        direction: OrganizeTokensDragAndDropControllerAutoScrollDirection,
        contentOffset: CGPoint,
        viewportSize: CGSize
    ) -> IndexPath? {
        // TODO: Andrey Fedorov - Add cache and/or maintain the current index to avoid repetitive O(N) work if possible (IOS-3884)
        let sortedItemsFrames = itemsFrames
            .filter { isIndexPathValid($0.key) }
            .sorted(by: \.value.minY)

        switch direction {
        case .top:
            if let lastValidTargetAtTheTop = sortedItemsFrames.last(where: { key, value in
                value.minY.rounded() < contentOffset.y.rounded() - .ulpOfOne
            }) {
                return lastValidTargetAtTheTop.key
            }
        case .bottom:
            if let firstValidTargetAtTheBottom = sortedItemsFrames.first(where: { key, value in
                value.maxY.rounded() > contentOffset.y.rounded() + viewportSize.height.rounded() - .ulpOfOne
            }) {
                return firstValidTargetAtTheBottom.key
            }
        }

        return nil
    }

    private func additionalAutoScrollTargets(
        scrollDirection: OrganizeTokensDragAndDropControllerAutoScrollDirection
    ) -> [AnyHashable] {
        switch scrollDirection {
        case .top:
            // We're scrolling to the top, so items at the bottom come first - therefore reversed order is used
            return topEdgeAdditionalAutoScrollTargets.reversed()
        case .bottom:
            return bottomEdgeAdditionalAutoScrollTargets
        }
    }
}
