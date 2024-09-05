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

protocol UnstakingModelStateProvider {
    var stakingAction: UnstakingModel.Action { get }

    var state: UnstakingModel.State { get }
    var statePublisher: AnyPublisher<UnstakingModel.State, Never> { get }
}

class UnstakingModel {
    // MARK: - Data

    private let _state = CurrentValueSubject<State, Never>(.loading)
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let transactionValidator: TransactionValidator
    private let action: Action
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        transactionValidator: TransactionValidator,
        action: Action,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.transactionValidator = transactionValidator
        self.action = action
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        updateState()
    }
}

// MARK: - UnstakingModelStateProvider

extension UnstakingModel: UnstakingModelStateProvider {
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

private extension UnstakingModel {
    func updateState() {
        estimatedFeeTask?.cancel()

        estimatedFeeTask = runTask(in: self) { model in
            do {
                model.update(state: .loading)
                let state = try await model.state()
                model.update(state: state)
            } catch {
                AppLog.shared.error(error)
                model.update(state: .networkError(error))
            }
        }
    }

    func state() async throws -> UnstakingModel.State {
        let estimateFee = try await stakingManager.estimateFee(action: action)

        if let error = validate(amount: action.amount, fee: estimateFee) {
            return error
        }

        return .ready(fee: estimateFee)
    }

    func validate(amount: Decimal, fee: Decimal) -> UnstakingModel.State? {
        do {
            try transactionValidator.validate(amount: makeAmount(value: amount), fee: makeFee(value: fee))
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
    private func send() async throws -> SendTransactionDispatcherResult {
        do {
            let transaction = try await stakingManager.transaction(action: action)
            let result = try await sendTransactionDispatcher.send(transaction: .staking(transaction))
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

extension UnstakingModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension UnstakingModel: SendAmountInput {
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

extension UnstakingModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        assertionFailure("We can not change amount in unstaking")
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

extension UnstakingModel: StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        stakingManager.statePublisher
    }
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
