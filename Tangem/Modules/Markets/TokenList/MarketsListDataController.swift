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
    var visibleRangeAreaPublisher: some Publisher<VisibleArea, Never> {
        visibleRangeAreaSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let dataProvider: MarketsListDataProvider

    private let lastAppearedIndexSubject: CurrentValueSubject<Int, Never> = .init(0)
    private let lastDisappearedIndexSubject: CurrentValueSubject<Int, Never> = .init(0)
    private let visibleRangeAreaSubject: CurrentValueSubject<VisibleArea, Never> = .init(VisibleArea(range: 0 ... 1, direction: .down))

    private var bag = Set<AnyCancellable>()
    private var isViewVisible: Bool

    // MARK: - Init

    init(dataProvider: MarketsListDataProvider, isViewVisible: Bool) {
        self.dataProvider = dataProvider
        self.isViewVisible = isViewVisible

        bind()
    }

    func update(viewDidAppear: Bool) {
        isViewVisible = viewDidAppear
    }

    // MARK: - Private Implementation

    private func bind() {
        lastAppearedIndexSubject.dropFirst().removeDuplicates()
            .combineLatest(lastDisappearedIndexSubject.dropFirst().removeDuplicates())
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
    }

    private func fetchMoreIfPossible(with range: ClosedRange<Int>) {
        guard dataProvider.canFetchMore else {
            return
        }

        let itemsInUpperBufferZone = dataProvider.items.count - range.upperBound
        if itemsInUpperBufferZone < Constants.itemsInBufferZone {
            dataProvider.fetchMore()
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
