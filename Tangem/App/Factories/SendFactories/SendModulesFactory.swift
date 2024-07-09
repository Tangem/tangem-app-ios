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
        let sendTransactionDispatcher = makeSendTransactionDispatcher()

        let sendModel = makeSendModel(
            sendFeeInteractor: sendFeeInteractor,
            informationRelevanceService: informationRelevanceService,
            sendTransactionDispatcher: sendTransactionDispatcher,
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
            sendSummaryInteractor: makeSendSummaryInteractor(input: sendModel, output: sendModel, sendTransactionDispatcher: sendTransactionDispatcher),
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
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        editableType: SendSummaryViewModel.EditableType
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            editableType: editableType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
        )
    }

    func makeSendSummaryInteractor(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendTransactionDispatcher: any SendTransactionDispatcher
    ) -> SendSummaryInteractor {
        CommonSendSummaryInteractor(
            input: input,
            output: output,
            sendTransactionDispatcher: sendTransactionDispatcher,
            descriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )
    }

    func makeSendFinishViewModel(addressTextViewHeightModel: AddressTextViewHeightModel) -> SendFinishViewModel {
        let settings = SendFinishViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            isFixedFee: builder.makeFeeOptions().count == 1
        )

        return SendFinishViewModel(
            settings: settings,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
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
        sendTransactionDispatcher: any SendTransactionDispatcher,
        type: SendType
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            walletModel: walletModel,
            sendTransactionDispatcher: sendTransactionDispatcher,
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

    func makeSendSummarySectionViewModelFactory() -> SendSummarySectionViewModelFactory {
        return SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: builder.isFeeApproximate(),
            currencyId: walletModel.tokenItem.currencyId,
            tokenIconInfo: builder.makeTokenIconInfo()
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

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        SendTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeSendTransactionDispatcher() -> SendTransactionDispatcher {
        CommonSendTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: transactionSigner
        )
    }
}
