//
//  UnstakingModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine
import BlockchainSdk
import TangemFoundation

protocol UnstakingModelStateProvider {
    var stakedBalance: Decimal { get }
    var stakingAction: UnstakingModel.Action { get }

    var state: UnstakingModel.State { get }
    var statePublisher: AnyPublisher<UnstakingModel.State, Never> { get }
}

class UnstakingModel {
    // MARK: - Data

    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _state = CurrentValueSubject<State, Never>(.loading)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let transactionDispatcher: TransactionDispatcher
    private let transactionValidator: TransactionValidator
    private let initialAction: Action
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
        initialAction = action
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        let fiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(action.amount, currencyId: $0)
        }

        _amount = CurrentValueSubject(SendAmount(type: .typical(crypto: action.amount, fiat: fiat)))

        logOpenScreen()
    }
}

// MARK: - UnstakingModelStateProvider

extension UnstakingModel: UnstakingModelStateProvider {
    var stakedBalance: Decimal {
        initialAction.amount
    }

    var stakingAction: Action {
        let amount = _amount.value?.crypto ?? initialAction.amount
        return Action(amount: amount, validatorType: initialAction.validatorType, type: initialAction.type)
    }

    var state: State {
        _state.value
    }

    var statePublisher: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension UnstakingModel {
    func updateState() {
        guard let amount = _amount.value?.crypto else { return }

        estimatedFeeTask?.cancel()

        estimatedFeeTask = TangemFoundation.runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let state = try await model.state(amount: amount)
                model.update(state: state)
            } catch _ as CancellationError {
                // Do nothing
            } catch {
                AppLog.shared.error(error)
                model.update(state: .networkError(error))
            }
        }
    }

    func state(amount: Decimal) async throws -> UnstakingModel.State {
        let estimateFee = try await stakingManager.estimateFee(action: stakingAction)

        if let error = validate(amount: amount, fee: estimateFee) {
            return error
        }

        return .ready(fee: estimateFee)
    }

    func validate(amount: Decimal, fee: Decimal) -> UnstakingModel.State? {
        do {
            try transactionValidator.validate(fee: makeFee(value: fee).amount)
            return nil
        } catch let error as ValidationError {
            return .validationError(error, fee: fee)
        } catch {
            return .networkError(error)
        }
    }

    func update(state: UnstakingModel.State) {
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

private extension UnstakingModel {
    private func send() async throws -> TransactionDispatcherResult {
        if let analyticsEvent = initialAction.type.analyticsEvent {
            Analytics.log(event: analyticsEvent, params: [.validator: initialAction.validatorInfo?.name ?? ""])
        }

        guard let amountCrypto = amount?.crypto else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        do {
            let transaction = try await stakingManager.transaction(action: stakingAction)
            let result = try await transactionDispatcher.send(transaction: .staking(transaction))
            proceed(result: result)
            stakingManager.transactionDidSent(action: stakingAction)

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
            .walletForm: result.signerType,
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

extension UnstakingModel: SendFeeLoader {
    func updateFees() {
        updateState()
    }
}

// MARK: - SendAmountInput

extension UnstakingModel: SendAmountInput {
    var amount: SendAmount? {
        _amount.value
    }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension UnstakingModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendFeeInput

extension UnstakingModel: SendFeeInput {
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

extension UnstakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension UnstakingModel: SendSummaryInput, SendSummaryOutput {
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

// MARK: - SendFinishInput

extension UnstakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension UnstakingModel: SendBaseInput, SendBaseOutput {
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

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension UnstakingModel: NotificationTapDelegate {
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

extension UnstakingModel: StakingBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { _amount.value?.crypto.flatMap { makeAmount(value: $0) } }

    var bsdkFee: BlockchainSdk.Fee? { selectedFee.value.value }

    var isFeeIncluded: Bool { false }

    var validator: ValidatorInfo? { initialAction.validatorInfo }

    var selectedPolicy: ApprovePolicy? { nil }

    var approveViewModelInput: (any ApproveViewModelInput)? { nil }

    var stakingActionType: TangemStaking.StakingAction.ActionType? { .unstake }
}

extension UnstakingModel {
    typealias Action = StakingAction

    enum State {
        case loading
        case ready(fee: Decimal)
        case validationError(ValidationError, fee: Decimal)
        case networkError(Error)
    }
}

// MARK: Analytics

private extension UnstakingModel {
    func logOpenScreen() {
        switch initialAction.type {
        case .pending(.claimRewards), .pending(.restakeRewards):
            Analytics.log(
                event: .stakingRewardScreenOpened,
                params: [.validator: initialAction.validatorInfo?.address ?? ""]
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

extension UnstakingModel.Action.ActionType {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .stake: .stakingButtonStake
        case .unstake: .stakingButtonUnstake
        case .pending(let pending): pending.analyticsEvent
        }
    }
}
