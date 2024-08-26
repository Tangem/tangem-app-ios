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
    var state: UnstakingModel.State { get }
    var statePublisher: AnyPublisher<UnstakingModel.State, Never> { get }
}

class UnstakingModel {
    // MARK: - Data

    private let _state: CurrentValueSubject<State, Never>
    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _isLoading = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private injections

    private let stakingManager: StakingManager
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let stakingTransactionMapper: StakingTransactionMapper
    private let action: StakingAction
    private let amountTokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private var estimatedFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        stakingManager: StakingManager,
        sendTransactionDispatcher: SendTransactionDispatcher,
        stakingTransactionMapper: StakingTransactionMapper,
        action: StakingAction,
        amountTokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.stakingTransactionMapper = stakingTransactionMapper
        self.action = action
        self.amountTokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem

        _state = .init(.init(action: action, fee: .loading))
        updateState()
    }
}

// MARK: - UnstakingModelStateProvider

extension UnstakingModel: UnstakingModelStateProvider {
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
                model.update(fee: .loading)
                let fee = try await model.fee()
                model.update(fee: .loaded(fee))
            } catch {
                AppLog.shared.error(error)
                model.update(fee: .failedToLoad(error: error))
            }
        }
    }

    func update(fee: LoadingValue<Decimal>) {
        _state.send(.init(action: action, fee: fee))
    }

    func fee() async throws -> Decimal {
        return try await stakingManager.estimateFee(action: action)
    }

    func mapToSendFee(_ state: State?) -> SendFee {
        switch state {
        case .none:
            return SendFee(option: .market, value: .failedToLoad(error: CommonError.noData))
        case .some(let state):
            let newValue = state.fee.mapValue { value in
                Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
            }

            return SendFee(option: .market, value: newValue)
        }
    }
}

// MARK: - Send

private extension UnstakingModel {
    private func send() async throws -> SendTransactionDispatcherResult {
        let transactionInfo = try await stakingManager.transaction(action: action)
        let transaction = stakingTransactionMapper.mapToStakeKitTransaction(transactionInfo: transactionInfo, value: action.amount)

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

extension UnstakingModel: SendFeeLoader {
    func updateFees() {}
}

// MARK: - SendAmountInput

extension UnstakingModel: SendAmountInput {
    var amount: SendAmount? {
        let fiat = amountTokenItem.currencyId.flatMap {
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
        _state.map { $0.fee.value != nil }.eraseToAnyPublisher()
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

    struct State: Hashable {
        let action: StakingAction
        let fee: LoadingValue<Decimal>
    }
}
