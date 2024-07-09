//
//  SendModulesStepsBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct SendModulesStepsBuilder {
    private let userWalletName: String
    private let walletModel: WalletModel

    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(userWalletName: String, walletModel: WalletModel) {
        self.userWalletName = userWalletName
        self.walletModel = walletModel
    }

    func isFeeApproximate() -> Bool {
        walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType)
    }

    func makeTokenIconInfo() -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    func makeFiatIconURL() -> URL {
        IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func makeSendWalletInfo(canUseFiatCalculation: Bool) -> SendWalletInfo {
        let tokenIconInfo = makeTokenIconInfo()

        return SendWalletInfo(
            walletName: userWalletName,
            balanceValue: walletModel.balanceValue,
            balance: Localization.sendWalletBalanceFormat(walletModel.balance, walletModel.fiatBalance),
            blockchain: walletModel.blockchainNetwork.blockchain,
            currencyId: walletModel.tokenItem.currencyId,
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: isFeeApproximate(),
            tokenIconInfo: tokenIconInfo,
            cryptoIconURL: tokenIconInfo.imageURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            amountFractionDigits: walletModel.tokenItem.decimalCount,
            feeFractionDigits: walletModel.feeTokenItem.decimalCount,
            feeAmountType: walletModel.feeTokenItem.amountType,
            canUseFiatCalculation: canUseFiatCalculation
        )
    }

    func makeSuggestedWallets(userWalletModels: [UserWalletModel]) -> [SendDestinationViewModel.Settings.SuggestedWallet] {
        userWalletModels.reduce([]) { result, userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels
            return result + walletModels
                .filter { walletModel in
                    let ignoredAddresses = self.walletModel.wallet.addresses.map { $0.value }

                    return walletModel.blockchainNetwork.blockchain.networkId == self.walletModel.tokenItem.blockchain.networkId &&
                        walletModel.isMainToken &&
                        !ignoredAddresses.contains(walletModel.defaultAddress)
                }
                .map { walletModel in
                    (name: userWalletModel.name, address: walletModel.defaultAddress)
                }
        }
    }

    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: makeTokenIconInfo().imageURL,
            cryptoCurrencyCode: tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: walletModel.quote == nil
        )
    }

    func makeFeeOptions() -> [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            return [.slow, .market, .fast]
        }

        return [.market]
    }
}
