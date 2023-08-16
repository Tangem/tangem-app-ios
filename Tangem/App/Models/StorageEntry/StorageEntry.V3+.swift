//
//  StorageEntry.V3+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry.V3.Entry {
    var isCustom: Bool { id == nil }

    var isToken: Bool { contractAddress != nil }

    var walletModelId: WalletModel.ID {
        let converter = StorageEntriesConverter()

        if let token = converter.convertToToken(self) {
            return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .token(value: token)).id
        }

        return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id
    }
}
