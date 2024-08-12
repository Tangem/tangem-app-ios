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
import enum TangemExpress.ExpressApprovePolicy

class StakingModel {
    // TODO: Move it to TangemService layer
    typealias ApprovePolicy = TangemExpress.ExpressApprovePolicy

    // MARK: - Data

    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedValidator = CurrentValueSubject<LoadingValue<ValidatorInfo>, Never>(.loading)
    private let _state = CurrentValueSubject<LoadingValue<State>?, Never>(.none)
    private let _approvePolicy = CurrentValueSubject<ApprovePolicy, Never>(.unlimited)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let transactionCreator: TransactionCreator
    private var ethereumNetworkProvider: EthereumNetworkProvider?
    private var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?
    private let sourceAddress: String
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let stakingMapper: StakingMapper

    private var estimatedFeeTask: Task<Void, Never>?
    private var sendTransactionTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        transactionCreator: TransactionCreator,
        ethereumNetworkProvider: EthereumNetworkProvider?,
        sourceAddress: String,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.transactionCreator = transactionCreator
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.sourceAddress = sourceAddress
        tokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem

        stakingMapper = StakingMapper(
            amountTokenItem: amountTokenItem,
            feeTokenItem: feeTokenItem
        )

        bind()
    }
}

// MARK: - Public

extension StakingModel {
    var state: AnyPublisher<State, Never> {
        _state.compactMap { $0?.value }.eraseToAnyPublisher()
    }
}

// MARK: - Bind

private extension StakingModel {
    func bind() {
        Publishers
            .CombineLatest3(
                _amount.compactMap { $0?.crypto },
                _selectedValidator.compactMap { $0.value },
                _approvePolicy
            )
            .sink { [weak self] amount, validator, approvePolicy in
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

    private func inputDataDidChange(amount: Decimal, validator: String, approvePolicy: ApprovePolicy) {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model._state.send(.loading)
                let newState = try await model.state(amount: amount, validator: validator, approvePolicy: approvePolicy)
                model._state.send(.loaded(newState))
            } catch {
                model._state.send(.failedToLoad(error: error))
            }
        }
    }

    private func state(amount: Decimal, validator: String, approvePolicy: ApprovePolicy) async throws -> StakingModel.State {
        if let state = try await checkAllowanceIfNeeded(amount: amount, validator: validator, approvePolicy: approvePolicy) {
            return state
        }

        let estimateFee = try await stakingManager.estimateFee(
            action: StakingAction(amount: amount, validator: validator, type: .stake)
        )

        return .readyToStake(fee: estimateFee)
    }

    private func checkAllowanceIfNeeded(amount: Decimal, validator: String, approvePolicy: ApprovePolicy) async throws -> StakingModel.State? {
        guard tokenItem.blockchain.isEvm,
              let contract = tokenItem.contractAddress,
              let ethereumNetworkProvider,
              let ethereumTransactionDataBuilder else {
            return nil
        }

        let allowance = try await ethereumNetworkProvider.getAllowance(
            owner: sourceAddress,
            spender: validator,
            contractAddress: contract
        ).async()

        let weiAmount = amount * tokenItem.decimalValue
        let approveAmount = approvePolicy.amount(weiAmount)

        // If we don't have enough allowance
        guard allowance < approveAmount else {
            return nil
        }

        let data = try ethereumTransactionDataBuilder.buildForApprove(spender: validator, amount: approveAmount)
        let amount = BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0)
        let fee = try await ethereumNetworkProvider.getFee(destination: contract, value: amount.encodedForSend, data: data).async()

        // Use fastest
        guard let fee = fee[safe: 2] else {
            throw StakingModelError.approveFeeNotFound
        }

        return .readyToApprove(contract: contract, data: data, fee: fee)
    }

    func mapToSendFee(_ state: LoadingValue<State>?) -> SendFee {
        let value = state?.mapValue { state in
            Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: state.fee))
        }

        return SendFee(option: .market, value: value ?? .failedToLoad(error: CommonError.noData))
    }
}

// MARK: - Send

private extension StakingModel {
    private func send() async throws -> SendTransactionDispatcherResult {
        guard let amount = _amount.value?.crypto else {
            throw StakingModelError.amountNotFound
        }

        guard let validator = _selectedValidator.value.value else {
            throw StakingModelError.amountNotFound
        }

        let action = StakingAction(amount: amount, validator: validator.address, type: .stake)
        let transactionInfo = try await stakingManager.transaction(action: action)
        let transaction = stakingMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: amount)

        do {
            let result = try await sendTransactionDispatcher.send(
                transaction: .staking(transactionId: transactionInfo.id, transaction: transaction)
            )
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
             .stakingUnsupported,
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
        _state.map { $0?.value != nil }.eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        Publishers.CombineLatest(_amount, _state)
            .map { amount, state in
                guard let amount, let state = state?.value else {
                    return nil
                }

                return .staking(amount: amount, fee: state.fee)
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

    var isLoading: AnyPublisher<Bool, Never> {
        _isLoading.eraseToAnyPublisher()
    }

    func sendTransaction() async throws -> SendTransactionDispatcherResult {
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

// MARK: - ApproveService

extension StakingModel: ApproveService {
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

    func updateApprovePolicy(policy: ExpressApprovePolicy) {
        _approvePolicy.send(policy)
    }

    func sendApproveTransaction() async throws {
        guard case .readyToApprove(let contract, let data, let fee) = _state.value?.value else {
            throw StakingModelError.approveDataNotFound
        }

        let transaction = try await transactionCreator.createTransaction(
            amount: .init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0),
            fee: fee,
            destinationAddress: contract,
            contractAddress: contract
        )

        _ = try await sendTransactionDispatcher.send(transaction: .transfer(transaction))
    }
}

extension StakingModel {
    enum State: Hashable {
        case readyToApprove(contract: String, data: Data, fee: Fee)
        case readyToStake(fee: Decimal)

        var fee: Decimal {
            switch self {
            case .readyToApprove(_, _, let fee): fee.amount.value
            case .readyToStake(let fee): fee
            }
        }
    }
}

enum StakingModelError: String, Hashable, Error {
    case amountNotFound
    case validatorNotFound
    case approveFeeNotFound
    case approveDataNotFound
}
