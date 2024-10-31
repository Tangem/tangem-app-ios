//
//  MarketsListDataController.swift
//  Tangem
//
//  Created by skibinalexander on 18.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

class MarketsListDataController {
    var hotAreaPublisher: some Publisher<VisibleArea, Never> {
        hotAreaSubject
    }

    var hotArea: VisibleArea {
        hotAreaSubject.value
    }

    // MARK: - Private Properties

    private weak var dataFetcher: MarketsListDataFetcher?
    private weak var cellsStateUpdater: MarketsListStateUpdater?

    private let lastAppearedIndexSubject: CurrentValueSubject<Int, Never> = .init(0)
    private let lastDisappearedIndexSubject: CurrentValueSubject<Int, Never> = .init(0)
    private let visibleRangeAreaSubject: CurrentValueSubject<VisibleArea, Never> = .init(VisibleArea(range: 0 ... 1, direction: .down))
    private let hotAreaSubject: CurrentValueSubject<VisibleArea, Never> = .init(VisibleArea(range: 0 ... 1, direction: .down))

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        dataFetcher: MarketsListDataFetcher,
        cellsStateUpdater: MarketsListStateUpdater?
    ) {
        self.dataFetcher = dataFetcher
        self.cellsStateUpdater = cellsStateUpdater

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        lastAppearedIndexSubject.dropFirst().removeDuplicates()
            .combineLatest(lastDisappearedIndexSubject.removeDuplicates())
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { elements in
                let (controller, (appearedIndex, disappearedIndex)) = elements

                let range: ClosedRange<Int>
                let direction: Direction
                if appearedIndex > disappearedIndex {
                    direction = .down
                    range = disappearedIndex ... appearedIndex
                } else {
                    direction = .up
                    range = appearedIndex ... disappearedIndex
                }

                let visibleArea = VisibleArea(range: range, direction: direction)
                controller.visibleRangeAreaSubject.send(visibleArea)
            })
            .store(in: &bag)

        visibleRangeAreaSubject
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { controller, visibleArea in
                switch visibleArea.direction {
                case .down:
                    controller.fetchMoreIfPossible(with: visibleArea.range)
                case .up:
                    break
                }
            }
            .store(in: &bag)

        visibleRangeAreaSubject.dropFirst().removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .compactMap { dataController, newVisibleArea in
                guard
                    let dataFetcher = dataController.dataFetcher,
                    dataFetcher.totalItems > 0
                else {
                    return nil
                }
                let numberOfItemsInBufferZone = Constants.itemsInBufferZone
                let lowerBound = max(0, newVisibleArea.range.lowerBound - numberOfItemsInBufferZone)
                let upperBound = min(dataFetcher.totalItems - 1, newVisibleArea.range.upperBound + numberOfItemsInBufferZone)
                return .init(
                    range: min(lowerBound, upperBound) ... max(lowerBound, upperBound),
                    direction: newVisibleArea.direction
                )
            }
            .assign(to: \.value, on: hotAreaSubject, ownership: .weak)
            .store(in: &bag)

        hotAreaSubject.dropFirst()
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink { elements in
                let (dataController, (oldHotArea, newHotArea)) = elements
                let oldHotAreaRange = oldHotArea?.range
                let newHotAreaRange = newHotArea.range

                guard let oldHotAreaRange else {
                    dataController.cellsStateUpdater?.setupUpdates(for: newHotAreaRange)
                    return
                }

                var rangeToInvalidate: ClosedRange<Int>?
                var rangeToSetupUpdates: ClosedRange<Int>

                switch newHotArea.direction {
                case .down:
                    guard oldHotAreaRange.lowerBound < newHotAreaRange.lowerBound else {
                        rangeToInvalidate = nil
                        rangeToSetupUpdates = newHotAreaRange.lowerBound ... newHotAreaRange.upperBound
                        break
                    }

                    rangeToSetupUpdates = min(oldHotAreaRange.upperBound, newHotAreaRange.upperBound) ... max(oldHotAreaRange.upperBound, newHotAreaRange.upperBound)
                    rangeToInvalidate = oldHotAreaRange.lowerBound ... newHotAreaRange.lowerBound
                case .up:
                    guard newHotAreaRange.upperBound < oldHotAreaRange.upperBound else {
                        rangeToInvalidate = nil
                        rangeToSetupUpdates = newHotAreaRange.lowerBound ... newHotAreaRange.upperBound
                        break
                    }

                    rangeToSetupUpdates = min(newHotAreaRange.lowerBound, oldHotAreaRange.lowerBound) ... max(newHotAreaRange.lowerBound, oldHotAreaRange.lowerBound)
                    rangeToInvalidate = newHotAreaRange.upperBound ... oldHotAreaRange.upperBound
                }

                if let rangeToInvalidate {
                    dataController.cellsStateUpdater?.invalidateCells(in: rangeToInvalidate)
                }
                dataController.cellsStateUpdater?.setupUpdates(for: rangeToSetupUpdates)
            }
            .store(in: &bag)
    }

    private func fetchMoreIfPossible(with range: ClosedRange<Int>) {
        guard
            let dataFetcher,
            dataFetcher.canFetchMore
        else {
            return
        }

        let itemsInUpperBufferZone = dataFetcher.totalItems - range.upperBound
        if itemsInUpperBufferZone < Constants.itemsInBufferZone {
            dataFetcher.fetchMore()
        }
    }
}

extension MarketsListDataController {
    enum Direction {
        case up
        case down
    }

    struct VisibleArea: Equatable {
        let range: ClosedRange<Int>
        let direction: Direction
    }
}

// MARK: - MarketsListPrefetchDataSource

extension MarketsListDataController: MarketsListPrefetchDataSource {
    func prefetchRows(at index: Int) {
        lastAppearedIndexSubject.send(index)
    }

    func cancelPrefetchingForRows(at index: Int) {
        lastDisappearedIndexSubject.send(index)
    }
}

// MARK: - Constants

extension MarketsListDataController {
    enum Constants {
        static let itemsInBufferZone = 20
    }
}
