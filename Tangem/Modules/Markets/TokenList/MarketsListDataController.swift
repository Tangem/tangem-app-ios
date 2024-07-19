//
//  MarketsListDataController.swift
//  Tangem
//
//  Created by skibinalexander on 18.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsListDataController {
    var viewDidAppear: Bool

    // MARK: - Privaate Properties

    private let dataProvider: MarketsListDataProvider

    private let onAppearLastValue: CurrentValueSubject<Int, Never> = .init(0)
    private let onDisappearLastValue: CurrentValueSubject<Int, Never> = .init(0)
    private let visableRangeAreaValue: CurrentValueSubject<VisabaleArea, Never>

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(dataProvider: MarketsListDataProvider, viewDidAppear: Bool) {
        self.dataProvider = dataProvider
        self.viewDidAppear = viewDidAppear

        visableRangeAreaValue = .init(VisabaleArea(range: 0 ... dataProvider.items.count, direction: .down))

        bind()
    }

    func bind() {
        onAppearLastValue
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { controller, onAppearValue in
                let closeRange = min(onAppearValue, controller.onDisappearLastValue.value) ... max(onAppearValue, controller.onDisappearLastValue.value)
                let direction: Direction = onAppearValue > controller.onDisappearLastValue.value ? .down : .up

                controller
                    .visableRangeAreaValue
                    .send(.init(range: closeRange, direction: direction))
            }
            .store(in: &bag)

        onDisappearLastValue
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { controller, onDisappearValue in
                let closeRange = min(controller.onAppearLastValue.value, onDisappearValue) ... max(controller.onAppearLastValue.value, onDisappearValue)
                let direction: Direction = controller.visableRangeAreaValue.value.direction

                controller
                    .visableRangeAreaValue
                    .send(.init(range: closeRange, direction: direction))
            }
            .store(in: &bag)

        visableRangeAreaValue
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { controller, visabaleArea in
                if case .down = visabaleArea.direction {
                    controller.fetchMoreIfPossible(with: visabaleArea.range)
                }

                if case .up = visabaleArea.direction {
                    controller.removeLastIfPossible(with: visabaleArea.range)
                }
            }
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    private func fetchMoreIfPossible(with range: ClosedRange<Int>) {
        guard viewDidAppear, dataProvider.canFetchMore else {
            return
        }

        if (dataProvider.items.count - range.upperBound) < Constants.prefetchMoreCountRows {
            dataProvider.fetchMore()
        }
    }

    // Need for optimization in memory cache rows
    private func removeLastIfPossible(with range: ClosedRange<Int>) {
        let offsetToRemove = Constants.prefetchMoreCountRows * 2
        let findLastToRemoveRows = (dataProvider.items.count - range.upperBound) > offsetToRemove ? Constants.prefetchMoreCountRows : nil

        if let findLastToRemoveRows {
            dataProvider.removeItems(count: findLastToRemoveRows)
        }
    }
}

extension MarketsListDataController {
    enum Direction {
        case up
        case down
    }

    struct VisabaleArea: Equatable {
        let range: ClosedRange<Int>
        let direction: Direction
    }
}

// MARK: - MarketsListPrefetchDataSource

extension MarketsListDataController: MarketsListPrefetchDataSource {
    func prefetchRows(at index: Int) {
        onAppearLastValue.send(index)
    }

    func cancelPrefetchingForRows(at index: Int) {
        onDisappearLastValue.send(index)
    }
}

// MARK: - Constants

extension MarketsListDataController {
    enum Constants {
        static let prefetchMoreCountRows = 100
    }
}
