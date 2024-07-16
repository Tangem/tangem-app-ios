//
//  StakingFeeInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemStaking

class StakingFeeInteractor {
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?
    private weak var validatorsInput: StakingValidatorsInput?

    private let manager: StakingManager
    private let feeTokenItem: TokenItem

    private let _fee: CurrentValueSubject<LoadingValue<Fee>, Never> = .init(.loading)
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendFeeInput,
        output: SendFeeOutput,
        validatorsInput: StakingValidatorsInput,
        manager: StakingManager,
        feeTokenItem: TokenItem
    ) {
        self.input = input
        self.output = output
        self.validatorsInput = validatorsInput
        self.manager = manager
        self.feeTokenItem = feeTokenItem

        bind()
        bind(input: input, validatorsInput: validatorsInput)
    }

    private func bind() {
        _fee
            .withWeakCaptureOf(self)
            .compactMap { interactor, fee in
                interactor.mapToSendFee(fee: fee)
            }
            // Only once
            .first()
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                interactor.initialSelectedFeeUpdateIfNeeded(fee: fee)
            }
            .store(in: &bag)
    }

    private func bind(input: SendFeeInput, validatorsInput: StakingValidatorsInput) {
        Publishers.CombineLatest(
            input.cryptoAmountPublisher,
            validatorsInput.selectedValidatorPublisher
        )
//        .setFailureType(to: Error.self)
        .print("getFee 1 ->>")
        .withWeakCaptureOf(self)
        .asyncMap { interactor, args -> Result<Decimal, Error> in
            do {
                let fee = try await interactor.manager.getFee(amount: args.0, validator: args.1.address)
                return .success(fee)
            } catch {
                return .failure(error)
            }
        }
        .print("getFee 2 ->>")
//        .mapToResult()
        .sink(receiveValue: { [weak self] result in
            self?.feeDidLoad(result: result)
        })
        .store(in: &bag)
    }

    private func feeDidLoad(result: Result<Decimal, Error>) {
        switch result {
        case .success(let fee):
            let fee = Fee(.init(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee))
            _fee.send(.loaded(fee))
        case .failure(let error):
            AppLog.shared.error(error)
            _fee.send(.failedToLoad(error: error))
        }
    }
}

// MARK: - SendFeeInteractor

extension StakingFeeInteractor: SendFeeInteractor {
    var selectedFee: SendFee? {
        input?.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedFeePublisher
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        _fee.map { fee in
            [SendFee(option: .market, value: fee)]
        }
        .eraseToAnyPublisher()
    }

    var customFeeInputFieldModels: [SendCustomFeeInputFieldModel] { [] }

    func updateFees() {
        // TODO: Stake flow
    }

    func update(selectedFee: SendFee) {
        output?.feeDidChanged(fee: selectedFee)
    }
}

// MARK: - Private

private extension StakingFeeInteractor {
    func mapToSendFee(fee: LoadingValue<Fee>) -> SendFee {
        SendFee(option: .market, value: fee)
    }

    private func initialSelectedFeeUpdateIfNeeded(fee: SendFee) {
        guard input?.selectedFee == nil else {
            return
        }

        output?.feeDidChanged(fee: fee)
    }
}
