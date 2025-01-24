//
//  StakingSingleActionModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine
import BlockchainSdk

protocol StakingSingleActionModelStateProvider {
    var stakingAction: StakingSingleActionModel.Action { get }

    var state: StakingSingleActionModel.State { get }
    var statePublisher: AnyPublisher<StakingSingleActionModel.State, Never> { get }
}

class StakingSingleActionModel {
    // MARK: - Data

    private let _state = CurrentValueSubject<State, Never>(.loading)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let transactionDispatcher: TransactionDispatcher
    private let transactionValidator: TransactionValidator
    private let action: Action
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        transactionDispatcher: TransactionDispatcher,
        transactionValidator: TransactionValidator,
        action: Action,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.transactionDispatcher = transactionDispatcher
        self.transactionValidator = transactionValidator
        self.action = action
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        updateState()
        logOpenScreen()
    }
}

// MARK: - UnstakingModelStateProvider

extension StakingSingleActionModel: StakingSingleActionModelStateProvider {
    var stakingAction: Action {
        action
    }

    var state: State {
        _state.value
    }

    var statePublisher: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension StakingSingleActionModel {
    func updateState() {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let state = try await model.state()
                model.update(state: state)
            } catch {
                Analytics.error(error)
                model.update(state: .networkError(error))
            }
        }
    }

    func state() async throws -> StakingSingleActionModel.State {
        let estimateFee = try await stakingManager.estimateFee(action: action)

        if let error = validate(amount: action.amount, fee: estimateFee) {
            return error
        }

        return .ready(fee: estimateFee)
    }

    func validate(amount: Decimal, fee: Decimal) -> StakingSingleActionModel.State? {
        do {
            try transactionValidator.validate(fee: makeFee(value: fee).amount)
            return nil
        } catch let error as ValidationError {
            return .validationError(error, fee: fee)
        } catch {
            return .networkError(error)
        }
    }

    func update(state: StakingSingleActionModel.State) {
        _state.send(state)
    }

    func makeAmount(value: Decimal) -> BSDKAmount {
        .init(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func makeFee(value: Decimal) -> Fee {
        Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    func mapToSendFee(_ state: State) -> SendFee {
        switch state {
        case .loading:
            return SendFee(option: .market, value: .loading)
        case .networkError(let error):
            return SendFee(option: .market, value: .failedToLoad(error: error))
        case .validationError(_, let fee), .ready(let fee):
            return SendFee(option: .market, value: .loaded(makeFee(value: fee)))
        }
    }
}

// MARK: - Send

private extension StakingSingleActionModel {
    private func send() async throws -> TransactionDispatcherResult {
        if let analyticsEvent = action.type.analyticsEvent {
            Analytics.log(event: analyticsEvent, params: [.validator: action.validatorInfo?.name ?? ""])
        }

        do {
            let transaction = try await stakingManager.transaction(action: action)
            let result = try await transactionDispatcher.send(transaction: .staking(transaction))
            proceed(result: result)
            stakingManager.transactionDidSent(action: action)

            return result
        } catch let error as TransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error)
        }
    }

    private func proceed(result: TransactionDispatcherResult) {
        _transactionTime.send(Date())
        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceStaking.rawValue,
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: selectedFee.option.rawValue,
        ])
    }

    private func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .demoAlert,
             .userCancelled,
             .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .loadTransactionInfo,
             .actionNotSupported:
            break
        case .sendTxError:
            Analytics.log(event: .stakingErrorTransactionRejected, params: [.token: tokenItem.currencySymbol])
        }
    }
}

// MARK: - SendFeeLoader

extension StakingSingleActionModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension StakingSingleActionModel: SendAmountInput {
    var amount: SendAmount? {
        let fiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(action.amount, currencyId: $0)
        }

        return .init(type: .typical(crypto: action.amount, fiat: fiat))
    }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        Just(amount).eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension StakingSingleActionModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        assertionFailure("We can not change amount in rewards")
    }
}

// MARK: - SendFeeInput

extension StakingSingleActionModel: SendFeeInput {
    var selectedFee: SendFee {
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, fee in
                model.mapToSendFee(fee)
            }
            .eraseToAnyPublisher()
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        .just(output: [selectedFee])
    }

    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        amountPublisher.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        assertionFailure("We don't have destination in staking")
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension StakingSingleActionModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingSingleActionModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { state in
            switch state {
            case .loading, .validationError, .networkError:
                return false
            case .ready:
                return true
            }
        }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        // Do not show any text in the unstaking flow
        .just(output: nil)
    }
}

// MARK: - StakingValidatorsInput

extension StakingSingleActionModel: StakingValidatorsInput {
    var selectedValidator: ValidatorInfo? { action.validatorInfo }

    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> {
        Just(action.validatorInfo).compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension StakingSingleActionModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension StakingSingleActionModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isLoading.eraseToAnyPublisher()
    }

    func performAction() async throws -> TransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakingSingleActionModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension StakingSingleActionModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateState()
        case .openFeeCurrency:
            router?.openNetworkCurrency()
        default:
            assertionFailure("StakingModel doesn't support notification action \(action)")
        }
    }
}

// MARK: - StakingBaseDataBuilderInput

extension StakingSingleActionModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { makeAmount(value: action.amount) }

    var bsdkFee: BlockchainSdk.Fee? { selectedFee.value.value }

    var isFeeIncluded: Bool { false }

    var validator: ValidatorInfo? { action.validatorInfo }

    var selectedPolicy: ApprovePolicy? { nil }

    var approveViewModelInput: (any ApproveViewModelInput)? { nil }

    var stakingActionType: TangemStaking.StakingAction.ActionType? { action.type }
}

extension StakingSingleActionModel {
    typealias Action = StakingAction
    typealias State = UnstakingModel.State
}

// MARK: Analytics

private extension StakingSingleActionModel {
    func logOpenScreen() {
        switch action.type {
        case .pending(.claimRewards), .pending(.restakeRewards):
            Analytics.log(
                event: .stakingRewardScreenOpened,
                params: [.validator: action.validatorInfo?.address ?? ""]
            )
        default:
            break
        }
    }
}

private extension StakingAction.PendingActionType {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .withdraw: .stakingButtonWithdraw
        case .claimRewards: .stakingButtonClaim
        case .restakeRewards: .stakingButtonRestake
        default: nil
        }
    }
}
