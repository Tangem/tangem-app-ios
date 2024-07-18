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

    private var visableRangeAreaValue: CurrentValueSubject<Range<Int>, Never> = .init(0 ..< 0)

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(dataProvider: MarketsListDataProvider, viewDidAppear: Bool) {
        self.dataProvider = dataProvider
        self.viewDidAppear = viewDidAppear
    }

    func bind() {
        visableRangeAreaValue
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { visableRange in

                // TODO: - Need implement prefetch or update quoutes logic
            }
            .store(in: &bag)
    }
}

// MARK: - MarketsListPrefetchDataSource

extension MarketsListDataController: MarketsListPrefetchDataSource {
    func tokekItemViewModel(prefetchRowsAt index: Int) {
        print("prefetchRowsAt \(index)")

        guard viewDidAppear, dataProvider.canFetchMore else {
            return
        }

        if (dataProvider.items.count - index) < Constants.prefetchMoreCountRows {
            dataProvider.fetchMore()
        }
    }

    func tokekItemViewModel(cancelPrefetchingForRowsAt index: Int) {
        // проверить крутим назад удаляем записи на onDisappear
        // вызываем метод appear in
        // проверить когда вызывается Disappear
        // начинаем крутить отменяем таску,

        // AsyncTaskScheduler на обновление цены
    }
}

// MARK: - Constants

extension MarketsListDataController {
    enum Constants {
        static let prefetchMoreCountRows = 50
    }
}
