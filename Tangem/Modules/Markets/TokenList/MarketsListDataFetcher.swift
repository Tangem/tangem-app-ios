//
//  MarketsListDataFetcher.swift
//  Tangem
//
//  Created by Andrew Son on 20.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsListDataFetcher: AnyObject {
    var canFetchMore: Bool { get }
    var totalItems: Int { get }
    func fetchMore()
}
