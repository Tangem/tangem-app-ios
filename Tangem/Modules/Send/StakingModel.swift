//
//  StakingModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine
import BlockchainSdk
import TangemFoundation

protocol StakingModelStateProvider {
    var state: AnyPublisher<StakingModel.State, Never> { get }
}

class StakingModel {
    @Injected(\.stakingPendingTransactionsRepository) private var stakingPendingTransactionsRepository: StakingPendingTransactionsRepository

    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedValidator = CurrentValueSubject<LoadingValue<ValidatorInfo>, Never>(.loading)
    private let _state = CurrentValueSubject<State?, Never>(.none)
    private let _approvePolicy = CurrentValueSubject<ApprovePolicy, Never>(.unlimited)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let transactionCreator: TransactionCreator
    private let transactionValidator: TransactionValidator
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let stakingTransactionDispatcher: SendTransactionDispatcher
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let allowanceProvider: AllowanceProvider
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private let updateStateSubject = PassthroughSubject<Void, Never>()

    private var timerTask: Task<Void, Error>?
    private var estimatedFeeTask: Task<Void, Never>?
    private var sendTransactionTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        transactionCreator: TransactionCreator,
        transactionValidator: TransactionValidator,
        feeIncludedCalculator: FeeIncludedCalculator,
        stakingTransactionDispatcher: SendTransactionDispatcher,
        sendTransactionDispatcher: SendTransactionDispatcher,
        allowanceProvider: AllowanceProvider,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.transactionCreator = transactionCreator
        self.transactionValidator = transactionValidator
        self.feeIncludedCalculator = feeIncludedCalculator
        self.stakingTransactionDispatcher = stakingTransactionDispatcher
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.allowanceProvider = allowanceProvider
        tokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem

        bind()
    }
}

// MARK: - Public

extension StakingModel {
    var selectedPolicy: ApprovePolicy {
        _approvePolicy.value
    }
}

// MARK: - StakingModelStateProvider

extension StakingModel: StakingModelStateProvider {
    var state: AnyPublisher<State, Never> {
        _state.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - Bind

private extension StakingModel {
    func bind() {
        Publishers
            .CombineLatest4(
                _amount.compactMap { $0?.crypto },
                _selectedValidator.compactMap { $0.value },
                _approvePolicy,
                updateStateSubject.prepend(()) // CombineLatest has to have first element
            )
            .sink { [weak self] amount, validator, approvePolicy, _ in
                self?.inputDataDidChange(amount: amount, validator: validator.address, approvePolicy: approvePolicy)
            }
            .store(in: &bag)

        stakingManager
            .statePublisher
            .compactMap { $0.yieldInfo }
            .map { yieldInfo -> LoadingValue<ValidatorInfo>in
                let defaultValidator = yieldInfo.validators.first(where: { $0.address == yieldInfo.defaultValidator })
                if let validator = defaultValidator ?? yieldInfo.validators.first {
                    return .loaded(validator)
                }

                return .failedToLoad(error: StakingModelError.validatorNotFound)
            }
            // Only for initial set
            .first()
            .assign(to: \._selectedValidator.value, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func inputDataDidChange(amount: Decimal, validator: String, approvePolicy: ApprovePolicy) {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let newState = try await model.state(amount: amount, validator: validator, approvePolicy: approvePolicy)
                model.update(state: newState)
            } catch {
                model.update(state: .networkError(error))
            }
        }
    }

    func state(amount: Decimal, validator: String, approvePolicy: ApprovePolicy) async throws -> StakingModel.State {
        if let allowanceState = try await allowanceState(amount: amount, validator: validator, approvePolicy: approvePolicy) {
            switch allowanceState {
            case .permissionRequired(let approveData):
                stopTimer()

                if let validateError = validate(amount: amount, fee: approveData.fee.amount.value) {
                    return validateError
                }

                return .readyToApprove(approveData: approveData)

            case .approveTransactionInProgress:
                return try await .approveTransactionInProgress(
                    stakingFee: estimateFee(amount: amount, validator: validator)
                )

            case .enoughAllowance:
                stopTimer()
            }
        }

        let fee = try await estimateFee(amount: amount, validator: validator)
        let includeFee = feeIncludedCalculator.shouldIncludeFee(makeFee(value: fee), into: makeAmount(value: amount))
        let newAmount = includeFee ? amount - fee : amount

        if let validateError = validate(amount: newAmount, fee: fee) {
            return validateError
        }

        return .readyToStake(.init(amount: newAmount, validator: validator, fee: fee, isFeeIncluded: includeFee))
    }

    func validate(amount: Decimal, fee: Decimal) -> StakingModel.State? {
        do {
            let amount = makeAmount(value: amount)
            let fee = makeFee(value: fee)

            try transactionValidator.validate(amount: amount, fee: fee)
            return nil
        } catch let error as ValidationError {
            return .validationError(error: error, fee: fee)
        } catch {
            return .networkError(error)
        }
    }

    func estimateFee(amount: Decimal, validator: String) async throws -> Decimal {
        try await stakingManager.estimateFee(
            action: StakingAction(amount: amount, type: .stake(validator: validator))
        )
    }

    func allowanceState(amount: Decimal, validator: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState? {
        guard allowanceProvider.isSupportAllowance else {
            return nil
        }

        return try await allowanceProvider
            .allowanceState(amount: amount, spender: validator, approvePolicy: approvePolicy)
    }

    func mapToSendFee(_ state: State?) -> SendFee {
        switch state {
        case .none, .loading:
            return SendFee(option: .market, value: .loading)
        case .readyToApprove(let approveData):
            return SendFee(option: .market, value: .loaded(approveData.fee))
        case .readyToStake(let readyToStake):
            return SendFee(option: .market, value: .loaded(makeFee(value: readyToStake.fee)))
        case .approveTransactionInProgress(let fee),
             .validationError(_, let fee):
            return SendFee(option: .market, value: .loaded(makeFee(value: fee)))
        case .networkError(let error):
            return SendFee(option: .market, value: .failedToLoad(error: error))
        }
    }

    func update(state: State) {
        log("update state: \(state)")
        _state.send(state)
    }

    func makeAmount(value: Decimal) -> BSDKAmount {
        .init(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func makeFee(value: Decimal) -> Fee {
        Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    func log(_ args: String) {
        AppLog.shared.debug("[Staking] \(objectDescription(self)) \(args)")
    }
}

// MARK: - Timer

private extension StakingModel {
    func restartTimer() {
        log("Restart timer")
        timerTask?.cancel()
        timerTask = runTask(in: self) { model in
            try Task.checkCancellation()

            try await Task.sleep(seconds: 5)

            model.log("timer realised")
            model.updateStateSubject.send(())

            try Task.checkCancellation()

            model.restartTimer()
        }
    }

    func stopTimer() {
        log("Stop timer")
        timerTask?.cancel()
        timerTask = nil
    }
}

// MARK: - Send

private extension StakingModel {
    private func send() async throws -> SendTransactionDispatcherResult {
        guard case .readyToStake(let readyToStake) = _state.value else {
            throw StakingModelError.readyToStakeNotFound
        }

        do {
            let action = StakingAction(amount: readyToStake.amount, type: .stake(validator: readyToStake.validator))
            let transactionInfo = try await stakingManager.transaction(action: action)
            let result = try await stakingTransactionDispatcher.send(transaction: .staking(transactionInfo))
            stakingPendingTransactionsRepository.transactionDidSent(action: action, validator: _selectedValidator.value.value)

            proceed(result: result)
            return result
        } catch let error as SendTransactionDispatcherResult.Error {
            proceed(error: error)
            throw error
        } catch {
            throw error
        }
    }

    private func proceed(result: SendTransactionDispatcherResult) {
        _transactionTime.send(Date())
    }

    private func proceed(error: SendTransactionDispatcherResult.Error) {
        switch error {
        case .informationRelevanceServiceError,
             .informationRelevanceServiceFeeWasIncreased,
             .transactionNotFound,
             .demoAlert,
             .userCancelled,
             .sendTxError:
            // TODO: Add analytics
            break
        }
    }
}

// MARK: - SendFeeLoader

extension StakingModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension StakingModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension StakingModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - StakingValidatorsInput

extension StakingModel: StakingValidatorsInput {
    var selectedValidatorPublisher: AnyPublisher<TangemStaking.ValidatorInfo, Never> {
        _selectedValidator.compactMap { $0.value }.eraseToAnyPublisher()
    }
}

// MARK: - StakingValidatorsOutput

extension StakingModel: StakingValidatorsOutput {
    func userDidSelected(validator: TangemStaking.ValidatorInfo) {
        _selectedValidator.send(.loaded(validator))
    }
}

// MARK: - SendFeeInput

extension StakingModel: SendFeeInput {
    var selectedFee: SendFee {
        mapToSendFee(_state.value)
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, state in
                model.mapToSendFee(state)
            }
            .eraseToAnyPublisher()
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        .just(output: [selectedFee])
    }

    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
        _amount.compactMap { $0?.crypto }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        assertionFailure("We don't have destination in staking")
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension StakingModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        assertionFailure("We can not change fee in staking")
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension StakingModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _state.map { state in
            switch state {
            case .readyToStake, .readyToApprove:
                return true
            case .none, .loading, .approveTransactionInProgress, .validationError, .networkError:
                return false
            }
        }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        Publishers.CombineLatest3(_amount, _state, _selectedValidator)
            .map { amount, state, selectedValidator in
                guard let amount, let fee = state?.fee, let apr = selectedValidator.value?.apr else {
                    return nil
                }

                return .staking(amount: amount, fee: fee, apr: apr)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension StakingModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension StakingModel: SendBaseInput, SendBaseOutput {
    var isFeeIncluded: Bool { false }

    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isLoading.eraseToAnyPublisher()
    }

    func performAction() async throws -> SendTransactionDispatcherResult {
        _isLoading.send(true)
        defer { _isLoading.send(false) }

        return try await send()
    }
}

// MARK: - StakingNotificationManagerInput

extension StakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
}

// MARK: - NotificationTapDelegate

extension StakingModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateStateSubject.send(())
        default:
            assertionFailure("StakingModel doesn't support notification action \(action)")
        }
    }
}

// MARK: - ApproveViewModelInput

extension StakingModel: ApproveViewModelInput {
    var approveFeeValue: LoadingValue<Fee> {
        selectedFee.value
    }

    var approveFeeValuePublisher: AnyPublisher<LoadingValue<BlockchainSdk.Fee>, Never> {
        _state
            .withWeakCaptureOf(self)
            .map { model, state in
                model.mapToSendFee(state).value
            }
            .eraseToAnyPublisher()
    }

    func updateApprovePolicy(policy: ApprovePolicy) {
        _approvePolicy.send(policy)
    }

    func sendApproveTransaction() async throws {
        guard case .readyToApprove(let approveData) = _state.value else {
            throw StakingModelError.approveDataNotFound
        }

        let transaction = try await transactionCreator.buildTransaction(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            amount: 0,
            fee: approveData.fee,
            destination: .contractCall(contract: approveData.toContractAddress, data: approveData.txData)
        )

        _ = try await sendTransactionDispatcher.send(transaction: .transfer(transaction))
        allowanceProvider.didSendApproveTransaction(for: approveData.spender)
        updateStateSubject.send(())

        // Setup timer for autoupdate
        restartTimer()
    }
}

extension StakingModel {
    enum State {
        case loading
        case readyToApprove(approveData: ApproveTransactionData)
        case approveTransactionInProgress(stakingFee: Decimal)
        case readyToStake(ReadyToStake)
        case validationError(error: ValidationError, fee: Decimal)
        case networkError(Error)

        var fee: Decimal? {
            switch self {
            case .readyToApprove(let requiredApprove): requiredApprove.fee.amount.value
            case .approveTransactionInProgress(let fee): fee
            case .readyToStake(let model): model.fee
            case .loading, .validationError, .networkError: nil
            }
        }

        struct ReadyToStake {
            let amount: Decimal
            let validator: String
            let fee: Decimal
            let isFeeIncluded: Bool
        }
    }
}

enum StakingModelError: String, Hashable, Error {
    case readyToStakeNotFound
    case validatorNotFound
    case approveDataNotFound
}
