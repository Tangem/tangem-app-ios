//
//  StorageEntry.V2.Entry+WalletModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 13.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry.V2.Entry {
    var walletModelIds: [WalletModel.ID] {
        let mainCoinId = WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id
        let tokenCoinIds = tokens.map { token in
            return WalletModel.Id(
                blockchainNetwork: blockchainNetwork,
                amountType: .token(value: token)
            ).id
        }
        return [mainCoinId] + tokenCoinIds
    }
}
