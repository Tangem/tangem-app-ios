//
//  OrganizeTokensOptionsConverter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensOptionsConverter {
    func convert(
        _ groupType: StoredUserTokenList.Grouping
    ) -> OrganizeTokensOptions.Grouping {
        switch groupType {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .byBlockchainNetwork
        }
    }

    func convert(
        _ sortType: StoredUserTokenList.Sorting
    ) -> OrganizeTokensOptions.Sorting {
        switch sortType {
        case .manual:
            return .dragAndDrop
        case .byBalance:
            return .byBalance
        }
    }

    func convert(
        _ groupType: OrganizeTokensOptions.Grouping
    ) -> StoredUserTokenList.Grouping {
        switch groupType {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .byBlockchainNetwork
        }
    }

    func convert(
        _ sortType: OrganizeTokensOptions.Sorting
    ) -> StoredUserTokenList.Sorting {
        switch sortType {
        case .dragAndDrop:
            return .manual
        case .byBalance:
            return .byBalance
        }
    }
}
