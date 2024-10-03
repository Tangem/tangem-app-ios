//
//  UserTokensReorderingOptions.swift
//  Tangem
//
//  Created by Andrey Fedorov on 04.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum UserTokensReorderingOptions {
    enum Grouping {
        case none
        case byBlockchainNetwork
    }

    enum Sorting {
        case dragAndDrop
        case byBalance
    }
}

// MARK: - Convenience extensions

extension UserTokensReorderingOptions.Grouping {
    var isGrouped: Bool {
        switch self {
        case .none:
            return false
        case .byBlockchainNetwork:
            return true
        }
    }
}

extension UserTokensReorderingOptions.Sorting {
    var isSorted: Bool {
        switch self {
        case .dragAndDrop:
            return false
        case .byBalance:
            return true
        }
    }
}
