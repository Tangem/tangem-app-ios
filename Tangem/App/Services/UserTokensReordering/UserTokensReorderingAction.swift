//
//  UserTokensReorderingAction.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum UserTokensReorderingAction {
    case setGroupingOption(option: UserTokensReorderingOptions.Grouping)
    case setSortingOption(option: UserTokensReorderingOptions.Sorting)
    case reorder(reorderedWalletModelIds: [WalletModel.ID])
}
