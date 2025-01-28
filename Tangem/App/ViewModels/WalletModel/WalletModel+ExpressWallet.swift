//
//  WalletModel+ExpressWallet.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

extension WalletModel: ExpressWallet {
    var expressCurrency: TangemExpress.ExpressCurrency {
        tokenItem.expressCurrency
    }

    var decimalCount: Int {
        tokenItem.decimalCount
    }

    var feeCurrencyDecimalCount: Int {
        feeTokenItem.decimalCount
    }

    var isFeeCurrency: Bool {
        tokenItem == feeTokenItem
    }

    func getBalance() throws -> Decimal {
        guard let balanceValue = availableBalanceProvider.balanceType.value else {
            throw ExpressManagerError.amountNotFound
        }

        return balanceValue
    }

    func getFeeCurrencyBalance() -> Decimal {
        wallet.feeCurrencyBalance(amountType: amountType)
    }
}
