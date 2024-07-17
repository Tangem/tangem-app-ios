//
//  MarketsListPrefetchDataSource.swift
//  Tangem
//
//  Created by skibinalexander on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsListPrefetchDataSource: AnyObject {
    // Instructs your prefetch data source object to begin preparing data for the cells at the supplied index paths.
    func tokekItemViewModel(prefetchRowsAt index: Int)

    // Cancels a previously triggered data prefetch request.
    func tokekItemViewModel(cancelPrefetchingForRowsAt index: Int)
}
