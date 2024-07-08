//
//  SendDependenciesBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

struct SendDependenciesBuilder {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let userWalletName: String
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel

    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(userWalletName: String, walletModel: WalletModel, userWalletModel: UserWalletModel) {
        self.userWalletName = userWalletName
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
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

    func makeSendWalletInfo() -> SendWalletInfo {
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
            canUseFiatCalculation: quotesRepository.quote(for: walletModel.tokenItem) != nil
        )
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

    func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: makeFeeOptions().count == 1)
    }

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
    }

    func makeSendTransactionSender() -> SendTransactionSender {
        CommonSendTransactionSender(
            walletModel: walletModel,
            transactionSigner: userWalletModel.signer
        )
    }

    func makeSendModel(
        sendTransactionSender: any SendTransactionSender,
        type: SendType,
        router: SendRoutable
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            walletModel: walletModel,
            sendTransactionSender: sendTransactionSender,
            feeIncludedCalculator: feeIncludedCalculator,
            predefinedAmount: type.predefinedAmount,
            predefinedDestination: type.predefinedDestination,
            predefinedTag: type.predefinedTag
        )
    }
}
