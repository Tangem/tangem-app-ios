//
//  SendModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendModulesFactory {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let builder: SendModulesStepsBuilder

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel

        builder = .init(userWalletName: userWalletModel.name, walletModel: walletModel)
    }

    // MARK: - Modules

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let sendModel = makeSendModel(type: type)
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
        let walletInfo = builder.makeSendWalletInfo(canUseFiatCalculation: canUseFiatCalculation)

        return SendViewModel(
            walletInfo: walletInfo,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: transactionSigner,
            sendType: type,
            emailDataProvider: emailDataProvider,
            sendModel: sendModel,
            notificationManager: makeSendNotificationManager(sendModel: sendModel),
            customFeeService: makeCustomFeeService(sendModel: sendModel),
            fiatCryptoAdapter: makeSendFiatCryptoAdapter(walletInfo: walletInfo),
            keyboardVisibilityService: KeyboardVisibilityService(),
            factory: self,
            coordinator: coordinator
        )
    }

    func makeSendDestinationViewModel(
        sendModel: SendModel,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let transactionHistoryMapper = TransactionHistoryMapper(
            currencySymbol: sendModel.currencySymbol,
            walletAddresses: sendModel.walletAddresses,
            showSign: false
        )

        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let inputModel = SendDestinationViewModel.InputModel(suggestedWallets: suggestedWallets)

        return SendDestinationViewModel(
            inputModel: inputModel,
            input: sendModel,
            addressTextViewHeightModel: addressTextViewHeightModel,
            transactionHistoryMapper: transactionHistoryMapper
        )
    }

    func makeSendAmountViewModel(
        sendModel: SendModel,
        fiatCryptoAdapter: CommonSendFiatCryptoAdapter,
        walletInfo: SendWalletInfo
    ) -> SendAmountViewModel {
        SendAmountViewModel(
            input: sendModel,
            fiatCryptoAdapter: fiatCryptoAdapter,
            walletInfo: walletInfo
        )
    }

    func makeSendFeeViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        customFeeService: CustomFeeService?,
        walletInfo: SendWalletInfo
    ) -> SendFeeViewModel {
        SendFeeViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            customFeeService: customFeeService,
            walletInfo: walletInfo
        )
    }

    func makeSendSummaryViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        fiatCryptoAdapter: CommonSendFiatCryptoAdapter,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo
    ) -> SendSummaryViewModel {
        SendSummaryViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            fiatCryptoValueProvider: fiatCryptoAdapter,
            addressTextViewHeightModel: addressTextViewHeightModel,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    func makeSendFinishViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        fiatCryptoAdapter: CommonSendFiatCryptoAdapter,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo
    ) -> SendFinishViewModel? {
        SendFinishViewModel(
            input: sendModel,
            fiatCryptoValueProvider: fiatCryptoAdapter,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: feeTypeAnalyticsParameter,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    // MARK: - Dependencies

    private var emailDataProvider: EmailDataProvider {
        userWalletModel
    }

    private var transactionSigner: TransactionSigner {
        userWalletModel.signer
    }

    private var sendAddressService: SendAddressService {
        SendAddressServiceFactory(walletModel: walletModel).makeService()
    }

    private func makeSendModel(type: SendType) -> SendModel {
        SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            addressService: sendAddressService,
            sendType: type
        )
    }

    private func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )
    }

    private func makeCustomFeeService(sendModel: SendModel) -> CustomFeeService? {
        CustomFeeServiceFactory(input: sendModel, output: sendModel, walletModel: walletModel).makeService()
    }

    private func makeSendFiatCryptoAdapter(walletInfo: SendWalletInfo) -> CommonSendFiatCryptoAdapter {
        CommonSendFiatCryptoAdapter(
            cryptoCurrencyId: walletInfo.currencyId,
            currencySymbol: walletInfo.cryptoCurrencyCode,
            decimals: walletInfo.amountFractionDigits
        )
    }

    private func makeSendSummarySectionViewModelFactory(walletInfo: SendWalletInfo) -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )
    }
}
