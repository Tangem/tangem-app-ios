//
//  TokenDetailsRoutable.swift
//  Tangem
//
//  Created by Andrew Son on 09/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

protocol TokenDetailsRoutable: AnyObject {
    func dismiss()
    func openFeeCurrency(for model: WalletModel, userWalletModel: UserWalletModel)
    func openPendingExpressTransactionDetails(
        for pendingTransaction: PendingExpressTransaction,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}
