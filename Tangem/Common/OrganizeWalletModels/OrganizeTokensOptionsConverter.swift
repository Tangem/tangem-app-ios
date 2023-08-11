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
        _ groupType: UserTokenList.GroupType
    ) -> OrganizeTokensOptions.Grouping {
        switch groupType {
        case .none:
            return .none
        case .network:
            return .byBlockchainNetwork
        }
    }

    func convert(
        _ sortType: UserTokenList.SortType
    ) -> OrganizeTokensOptions.Sorting {
        switch sortType {
        case .manual:
            return .dragAndDrop
        case .balance:
            return .byBalance
        }
    }

    func convert(
        _ groupType: OrganizeTokensOptions.Grouping
    ) -> UserTokenList.GroupType {
        switch groupType {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .network
        }
    }

    func convert(
        _ sortType: OrganizeTokensOptions.Sorting
    ) -> UserTokenList.SortType {
        switch sortType {
        case .dragAndDrop:
            return .manual
        case .byBalance:
            return .balance
        }
    }
}
