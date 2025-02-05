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
import TangemExpress

struct SendDependenciesBuilder {
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func sendFlowActionType(actionType: StakingAction.ActionType) -> SendFlowActionType {
        switch actionType {
        case .stake, .pending(.stake): .stake
        case .unstake: .unstake
        case .pending(.claimRewards): .claimRewards
        case .pending(.withdraw): .withdraw
        case .pending(.restakeRewards): .restakeRewards
        case .pending(.voteLocked): .voteLocked
        case .pending(.unlockLocked): .unlockLocked
        case .pending(.restake): .restake
        case .pending(.claimUnstaked): .claimUnstaked
        }
    }

    func summaryTitle(action: SendFlowActionType) -> String {
        switch action {
        case .send: Localization.sendSummaryTitle(walletModel.tokenItem.currencySymbol)
        case .approve, .stake: "\(Localization.commonStake) \(walletModel.tokenItem.currencySymbol)"
        case .unstake: action.title
        case .withdraw: action.title
        case .claimRewards: action.title
        case .restakeRewards: action.title
        case .unlockLocked: action.title
        case .restake: action.title
        case .claimUnstaked: SendFlowActionType.withdraw.title
        default: action.title
        }
    }

    func summarySubtitle(action: SendFlowActionType) -> String? {
        switch action {
        case .send: walletName()
        case .approve, .stake, .restake: walletName()
        case .unstake: nil
        case .withdraw: nil
        case .claimRewards: nil
        case .restakeRewards: nil
        case .unlockLocked: nil
        default: nil
        }
    }

    func walletHeaderText(for actionType: SendFlowActionType) -> String {
        switch actionType {
        case .unstake: Localization.stakingStakedAmount
        default: walletName()
        }
    }

    func maxAmount(for amount: SendAmount?, actionType: SendFlowActionType) -> Decimal {
        switch actionType {
        case .unstake: amount?.crypto ?? 0
        default: walletModel.availableBalanceProvider.balanceType.value ?? 0
        }
    }

    func makeStakeAction() -> StakingAction {
        StakingAction(
            amount: (try? walletModel.getBalance()) ?? 0,
            validatorType: .empty,
            type: .stake
        )
    }

    func formattedBalance(for amount: SendAmount?, actionType: SendFlowActionType) -> String {
        let balanceFormatted: BalanceFormatted
        switch actionType {
        case .unstake:
            let formatter = BalanceFormatter()
            let cryptoFormatted = formatter.formatCryptoBalance(
                amount?.crypto,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let fiatFormatted = formatter.formatFiatBalance(amount?.fiat)
            balanceFormatted = .init(crypto: cryptoFormatted, fiat: fiatFormatted)
        default:
            balanceFormatted = .init(
                crypto: walletModel.availableBalanceProvider.formattedBalanceType.value,
                fiat: walletModel.fiatAvailableBalanceProvider.formattedBalanceType.value
            )
        }
        return Localization.commonCryptoFiatFormat(balanceFormatted.crypto, balanceFormatted.fiat)
    }

    func walletName() -> String {
        userWalletModel.name
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

    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: makeTokenIconInfo().imageURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
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

    func makeSendTransactionParametersBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: walletModel.tokenItem.blockchain)
    }

    func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: makeFeeOptions().count == 1)
    }

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider
        )
    }

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
    }

    func makeTransactionDispatcher() -> TransactionDispatcher {
        TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        )
        .makeSendDispatcher()
    }

    func makeStakingTransactionDispatcher(stakingManger: some StakingManager) -> TransactionDispatcher {
        StakingTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: userWalletModel.signer,
            pendingHashesSender: StakingDependenciesFactory().makePendingHashesSender(),
            stakingTransactionMapper: makeStakingTransactionMapper(),
            transactionStatusProvider: CommonStakeKitTransactionStatusProvider(stakingManager: stakingManger)
        )
    }

    func makeSendQRCodeService() -> SendQRCodeService {
        CommonSendQRCodeService(
            parser: QRCodeParser(
                amountType: walletModel.tokenItem.amountType,
                blockchain: walletModel.tokenItem.blockchain,
                decimalCount: walletModel.tokenItem.decimalCount
            )
        )
    }

    func makeFeeIncludedCalculator() -> FeeIncludedCalculator {
        CommonFeeIncludedCalculator(validator: walletModel.transactionValidator)
    }

    // MARK: - Send, Sell

    func makeSendModel(
        predefinedSellParameters: PredefinedSellParameters? = .none
    ) -> SendModel {
        let transactionDispatcher = makeTransactionDispatcher()
        let predefinedValues = mapToPredefinedValues(sellParameters: predefinedSellParameters)

        return SendModel(
            tokenItem: walletModel.tokenItem,
            balanceProvider: walletModel.availableBalanceProvider,
            transactionDispatcher: transactionDispatcher,
            transactionCreator: walletModel.transactionCreator,
            transactionSigner: userWalletModel.signer,
            feeIncludedCalculator: makeFeeIncludedCalculator(),
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            predefinedValues: predefinedValues
        )
    }

    func mapToPredefinedValues(sellParameters: PredefinedSellParameters?) -> SendModel.PredefinedValues {
        let source: SendModel.PredefinedValues.Source = sellParameters == nil ? .send : .sell
        let destination = sellParameters.map { SendAddress(value: $0.destination, source: .sellProvider) }
        let amount = sellParameters.map { sellParameters in
            let fiatValue = walletModel.tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(sellParameters.amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: sellParameters.amount, fiat: fiatValue))
        }

        // the additionalField is requried. Other can be optional
        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: walletModel.blockchainNetwork.blockchain) else {
                return .notSupported
            }

            guard let tag = sellParameters?.tag?.nilIfEmpty,
                  let params = try? makeSendTransactionParametersBuilder().transactionParameters(value: tag) else {
                return .empty(type: type)
            }

            return .filled(type: type, value: tag, params: params)
        }()

        return SendModel.PredefinedValues(source: source, destination: destination, tag: additionalField, amount: amount)
    }

    func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        switch walletModel.tokenItem.blockchain {
        case .koinos:
            KoinosSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        case .tron where walletModel.tokenItem.isToken:
            TronSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        default:
            CommonSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        }
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeSendBaseDataBuilder(input: SendBaseDataBuilderInput) -> SendBaseDataBuilder {
        CommonSendBaseDataBuilder(input: input, walletModel: walletModel, emailDataProvider: userWalletModel)
    }

    func makeSendFinishAnalyticsLogger(sendFeeInput: SendFeeInput) -> SendFinishAnalyticsLogger {
        CommonSendFinishAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            sendFeeInput: sendFeeInput
        )
    }

    // MARK: - Staking

    func makeStakingModel(stakingManager: some StakingManager) -> StakingModel {
        StakingModel(
            stakingManager: stakingManager,
            transactionCreator: walletModel.transactionCreator,
            transactionValidator: walletModel.transactionValidator,
            feeIncludedCalculator: makeStakingFeeIncludedCalculator(),
            stakingTransactionDispatcher: makeStakingTransactionDispatcher(stakingManger: stakingManager),
            transactionDispatcher: makeTransactionDispatcher(),
            allowanceProvider: makeAllowanceProvider(),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeUnstakingModel(stakingManager: some StakingManager, action: UnstakingModel.Action) -> UnstakingModel {
        UnstakingModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(stakingManger: stakingManager),
            transactionValidator: walletModel.transactionValidator,
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeRestakingModel(stakingManager: some StakingManager, action: RestakingModel.Action) -> RestakingModel {
        RestakingModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(stakingManger: stakingManager),
            transactionValidator: walletModel.transactionValidator,
            sendAmountValidator: makeStakingSendAmountValidator(stakingManager: stakingManager),
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingSingleActionModel(stakingManager: some StakingManager, action: UnstakingModel.Action) -> StakingSingleActionModel {
        StakingSingleActionModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(stakingManger: stakingManager),
            transactionValidator: walletModel.transactionValidator,
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingNotificationManager() -> StakingNotificationManager {
        CommonStakingNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeStakingSendAmountValidator(stakingManager: some StakingManager) -> SendAmountValidator {
        StakingSendAmountValidator(
            tokenItem: walletModel.tokenItem,
            validator: walletModel.transactionValidator,
            stakingManagerStatePublisher: stakingManager.statePublisher
        )
    }

    func makeUnstakingSendAmountValidator(
        stakingManager: some StakingManager,
        stakedAmount: Decimal
    ) -> SendAmountValidator {
        UnstakingSendAmountValidator(
            tokenItem: walletModel.tokenItem,
            stakedAmount: stakedAmount,
            stakingManagerStatePublisher: stakingManager.statePublisher
        )
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        StakingTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem)
    }

    func makeAllowanceProvider() -> AllowanceProvider {
        CommonAllowanceProvider(walletModel: walletModel)
    }

    func makeStakingTransactionMapper() -> StakingTransactionMapper {
        StakingTransactionMapper(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingAlertBuilder() -> SendAlertBuilder {
        StakingSendAlertBuilder()
    }

    func makeStakingFeeIncludedCalculator() -> FeeIncludedCalculator {
        StakingFeeIncludedCalculator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    func makeStakingAmountModifier(actionType: SendFlowActionType) -> SendAmountModifier {
        StakingAmountModifier(tokenItem: walletModel.tokenItem, actionType: actionType)
    }

    func makeStakingBaseDataBuilder(input: StakingBaseDataBuilderInput) -> StakingBaseDataBuilder {
        CommonStakingBaseDataBuilder(input: input, walletModel: walletModel, emailDataProvider: userWalletModel)
    }

    func makeStakingFinishAnalyticsLogger(
        actionType: SendFlowActionType,
        stakingValidatorsInput: StakingValidatorsInput
    ) -> SendFinishAnalyticsLogger {
        StakingFinishAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            actionType: actionType,
            stakingValidatorsInput: stakingValidatorsInput
        )
    }

    // MARK: - Onramp

    func makeOnrampModel(
        onrampManager: some OnrampManager,
        onrampDataRepository: some OnrampDataRepository,
        onrampRepository: some OnrampRepository
    ) -> OnrampModel {
        OnrampModel(
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: walletModel,
            onrampManager: onrampManager,
            onrampDataRepository: onrampDataRepository,
            onrampRepository: onrampRepository
        )
    }

    func makeOnrampDependencies(userWalletId: String) -> (
        manager: OnrampManager,
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository
    ) {
        let apiProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        let factory = TangemExpressFactory()
        let repository = factory.makeOnrampRepository(storage: CommonOnrampStorage())
        let dataRepository = factory.makeOnrampDataRepository(expressAPIProvider: apiProvider)
        let manager = factory.makeOnrampManager(
            expressAPIProvider: apiProvider,
            onrampRepository: repository,
            dataRepository: dataRepository,
            logger: AppLog.shared,
            analyticsLogger: CommonExpressAnalyticsLogger(tokenItem: walletModel.tokenItem)
        )

        return (
            manager: manager,
            repository: repository,
            dataRepository: dataRepository
        )
    }

    func makeOnrampBaseDataBuilder(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        providersBuilder: OnrampProvidersBuilder,
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) -> OnrampBaseDataBuilder {
        CommonOnrampBaseDataBuilder(
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            providersBuilder: providersBuilder,
            paymentMethodsBuilder: paymentMethodsBuilder,
            onrampRedirectingBuilder: onrampRedirectingBuilder
        )
    }

    func makeOnrampNotificationManager(input: OnrampNotificationManagerInput, delegate: NotificationTapDelegate) -> OnrampNotificationManager {
        CommonOnrampNotificationManager(input: input, delegate: delegate)
    }

    func makeOnrampFinishAnalyticsLogger(onrampProvidersInput: OnrampProvidersInput) -> SendFinishAnalyticsLogger {
        OnrampFinishAnalyticsLogger(tokenItem: walletModel.tokenItem, onrampProvidersInput: onrampProvidersInput)
    }

    func makePendingExpressTransactionsManager() -> PendingExpressTransactionsManager {
        CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: walletModel
        )
    }
}
