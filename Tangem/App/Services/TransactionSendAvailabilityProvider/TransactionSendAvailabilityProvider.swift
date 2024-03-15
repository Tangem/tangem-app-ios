//
//  TransactionSendAvailabilityProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TransactionSendAvailabilityProvider {
    func sendingRestrictions(walletModel: WalletModel) -> SendingRestrictions? {
        let wallet = walletModel.wallet

        if !AppUtils().canSignLongTransactions(tokenItem: walletModel.tokenItem) {
            return .cantSignLongTransactions
        }

        guard let currentAmount = wallet.amounts[walletModel.amountType], currentAmount.value > 0 else {
            return .zeroWalletBalance
        }

        // has pending tx
        if hasPendingTransactions(walletModel: walletModel) {
            return .hasPendingTransaction(blockchain: walletModel.tokenItem.blockchain)
        }

        // no fee
        if !wallet.hasFeeCurrency(amountType: walletModel.amountType), !currentAmount.isZero {
            return .zeroFeeCurrencyBalance(
                configuration: .init(
                    transactionAmountTypeName: walletModel.tokenItem.name,
                    feeAmountTypeName: walletModel.feeTokenItem.name,
                    feeAmountTypeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
                    feeAmountTypeIconName: walletModel.feeTokenItem.blockchain.iconNameFilled,
                    networkName: walletModel.tokenItem.networkName,
                    currencyButtonTitle: walletModel.tokenItem.blockchain.feeDisplayName
                )
            )
        }

        return nil
    }

    func hasPendingTransactions(walletModel: WalletModel) -> Bool {
        // For bitcoin we check only outgoing transaction
        // because we will not use unconfirmed utxo
        if case .bitcoin = walletModel.blockchainNetwork.blockchain {
            return walletModel.wallet.pendingTransactions.contains { !$0.isIncoming }
        }

        return !walletModel.wallet.pendingTransactions.isEmpty
    }
}

extension TransactionSendAvailabilityProvider {
    enum SendingRestrictions: Hashable {
        case zeroWalletBalance
        case cantSignLongTransactions
        case hasPendingTransaction(blockchain: Blockchain)
        case zeroFeeCurrencyBalance(configuration: NotEnoughFeeConfiguration)

        struct NotEnoughFeeConfiguration: Hashable {
            let transactionAmountTypeName: String
            let feeAmountTypeName: String
            let feeAmountTypeCurrencySymbol: String
            let feeAmountTypeIconName: String
            let networkName: String
            let currencyButtonTitle: String?
        }

        var description: String? {
            switch self {
            case .zeroWalletBalance:
                return nil
            case .cantSignLongTransactions:
                return Localization.warningLongTransactionMessage
            case .hasPendingTransaction(let blockchain):
                switch blockchain.feePaidCurrency {
                case .coin:
                    return Localization.warningSendBlockedPendingTransactionsMessage(blockchain.currencySymbol)
                case .token, .sameCurrency:
                    return Localization.warningSendBlockedPendingTransactionsInBlockchainMessage(blockchain.displayName)
                }
            case .zeroFeeCurrencyBalance(let configuration):
                return Localization.warningSendBlockedFundsForFeeMessage(
                    configuration.transactionAmountTypeName,
                    configuration.networkName,
                    configuration.transactionAmountTypeName,
                    configuration.feeAmountTypeName,
                    configuration.feeAmountTypeCurrencySymbol
                )
            }
        }
    }
}
