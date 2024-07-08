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

    // MARK: - ViewModels

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let sendFeeInteractor = makeSendFeeInteractor(
            predefinedAmount: type.predefinedAmount,
            predefinedDestination: type.predefinedDestination
        )

        let informationRelevanceService = makeInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)

        let sendModel = makeSendModel(
            sendFeeInteractor: sendFeeInteractor,
            informationRelevanceService: informationRelevanceService,
            type: type
        )
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
        let walletInfo = builder.makeSendWalletInfo(canUseFiatCalculation: canUseFiatCalculation)
        let initial = SendViewModel.Initial(feeOptions: builder.makeFeeOptions())
        sendFeeInteractor.setup(input: sendModel, output: sendModel)

        return SendViewModel(
            initial: initial,
            walletInfo: walletInfo,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: transactionSigner,
            sendType: type,
            emailDataProvider: emailDataProvider,
            sendModel: sendModel,
            notificationManager: makeSendNotificationManager(sendModel: sendModel),
            sendFeeInteractor: sendFeeInteractor,
            keyboardVisibilityService: KeyboardVisibilityService(),
            sendAmountValidator: makeSendAmountValidator(),
            factory: self,
            coordinator: coordinator
        )
    }

    func makeSendDestinationViewModel(
        input: SendDestinationInput,
        output: SendDestinationOutput,
        sendType: SendType,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let additionalFieldType = SendAdditionalFields.fields(for: tokenItem.blockchain)
        let settings = SendDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let interactor = makeSendDestinationInteractor(input: input, output: output)

        let viewModel = SendDestinationViewModel(
            settings: settings,
            interactor: interactor,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let address = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
        viewModel.setExternally(address: address, additionalField: sendType.predefinedTag)

        return viewModel
    }

    func makeSendAmountViewModel(
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator,
        sendType: SendType
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData(),
            predefinedAmount: sendType.predefinedAmount?.value
        )

        let interactor = makeSendAmountInteractor(input: input, output: output, validator: validator)

        return SendAmountViewModel(initial: initital, interactor: interactor)
    }

    func makeSendFeeViewModel(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) -> SendFeeViewModel {
        let settings = SendFeeViewModel.Settings(tokenItem: walletModel.tokenItem)

        return SendFeeViewModel(
            settings: settings,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router
        )
    }

    func makeSendSummaryViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        sendFeeInteractor: SendFeeInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo
    ) -> SendSummaryViewModel {
        let initial = SendSummaryViewModel.Initial(tokenItem: walletModel.tokenItem)

        return SendSummaryViewModel(
            initial: initial,
            input: sendModel,
            notificationManager: notificationManager,
            sendFeeInteractor: sendFeeInteractor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    func makeSendFinishViewModel(
        amount: SendAmount?,
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo
    ) -> SendFinishViewModel? {
        let initial = SendFinishViewModel.Initial(tokenItem: walletModel.tokenItem, amount: amount)

        return SendFinishViewModel(
            initial: initial,
            input: sendModel,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: feeTypeAnalyticsParameter,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }
}

// MARK: - Dependencies

private extension SendModulesFactory {
    var emailDataProvider: EmailDataProvider {
        return userWalletModel
    }

    var transactionSigner: TransactionSigner {
        return userWalletModel.signer
    }

    func makeSendModel(
        sendFeeInteractor: SendFeeInteractor,
        informationRelevanceService: InformationRelevanceService,
        type: SendType
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            sendFeeInteractor: sendFeeInteractor,
            feeIncludedCalculator: feeIncludedCalculator,
            informationRelevanceService: informationRelevanceService,
            sendType: type
        )
    }

    func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        return CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )
    }

    func makeSendSummarySectionViewModelFactory(walletInfo: SendWalletInfo) -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )
    }

    func makeSendDestinationInteractor(
        input: SendDestinationInput,
        output: SendDestinationOutput
    ) -> SendDestinationInteractor {
        let parametersBuilder = SendTransactionParametersBuilder(blockchain: walletModel.tokenItem.blockchain)

        return CommonSendDestinationInteractor(
            input: input,
            output: output,
            validator: makeSendDestinationValidator(),
            transactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
            transactionHistoryMapper: makeTransactionHistoryMapper(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .fields(for: walletModel.tokenItem.blockchain),
            parametersBuilder: parametersBuilder
        )
    }

    func makeSendDestinationValidator() -> SendDestinationValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let validator = CommonSendDestinationValidator(
            walletAddresses: walletModel.addresses,
            addressService: addressService,
            supportsCompound: walletModel.wallet.blockchain.supportsCompound
        )

        return validator
    }

    func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(walletModel: walletModel)
    }

    func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )
    }

    func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    func makeSendAmountInteractor(
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            input: input,
            output: output,
            validator: validator,
            type: .crypto
        )
    }

    func makeSendFeeInteractor(predefinedAmount: Amount?, predefinedDestination: String?) -> SendFeeInteractor {
        let customFeeService = CustomFeeServiceFactory(walletModel: walletModel).makeService()
        let interactor = CommonSendFeeInteractor(
            provider: makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService,
            predefinedAmount: predefinedAmount,
            predefinedDestination: predefinedDestination
        )
        customFeeService?.setup(input: interactor, output: interactor)
        return interactor
    }

    func makeSendFeeProvider() -> SendFeeProvider {
        CommonSendFeeProvider(walletModel: walletModel)
    }

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
    }
}

private extension Blockchain {
    var supportsCompound: Bool {
        switch self {
        case .bitcoin,
             .bitcoinCash,
             .litecoin,
             .dogecoin,
             .dash,
             .kaspa,
             .ravencoin,
             .ducatus:
            return true
        default:
            return false
        }
    }
}
