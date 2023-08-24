//
//  StorageEntriesList.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// @available(*, deprecated, message: "Get rid of this temporary alias and rename StorageEntriesList")
typealias StoredUserTokenList = StorageEntriesList

// TODO: Andrey Fedorov - Remove to `StoredUserTokenList`
struct StorageEntriesList: Codable, Equatable {
    enum Grouping: Codable, Equatable {
        case none
        case byBlockchainNetwork
    }

    enum Sorting: Codable, Equatable {
        case manual
        case byBalance
    }

    struct Entry: Codable, Equatable {
        let id: String?
        let name: String
        let symbol: String
        let decimalCount: Int
        let blockchainNetwork: BlockchainNetwork
        let contractAddress: String?
    }

    let entries: [Entry]
    let grouping: Grouping
    let sorting: Sorting
}

// MARK: - Convenience extensions

extension StorageEntriesList {
    static var empty: Self { Self(entries: [], grouping: .none, sorting: .manual) }
}

extension StorageEntriesList.Entry {
    var isToken: Bool { contractAddress != nil }
    var isCustom: Bool { id == nil }
}
