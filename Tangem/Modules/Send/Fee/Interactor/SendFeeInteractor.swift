//
//  SendFeeInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFeeInteractor {
    var selectedFee: SendFee? { get }

    func update(selectedFee: SendFee)
    func updateFees()

    func feesPublisher() -> AnyPublisher<[SendFee], Never>
    func selectedFeePublisher() -> AnyPublisher<SendFee?, Never>

    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel]

    func setup(input: SendFeeInput, output: SendFeeOutput)
}

class CommonSendFeeInteractor {
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?

    private let provider: SendFeeProvider
    private var customFeeService: CustomFeeService?
    private let _cryptoAmount: CurrentValueSubject<Amount?, Never>
    private let _destination: CurrentValueSubject<String?, Never>

    private let _fees: CurrentValueSubject<LoadingValue<[Fee]>, Never> = .init(.loading)
    private let _customFee: CurrentValueSubject<Fee?, Never> = .init(.none)

    private let defaultFeeOptions: [FeeOption]
    private var feeOptions: [FeeOption] {
        var options = defaultFeeOptions
        if supportCustomFee {
            options.append(.custom)
        }
        return options
    }

    private var supportCustomFee: Bool {
        customFeeService != nil
    }

    private var cryptoAmountSubscribtion: AnyCancellable?
    private var destinationAddressSubscribtion: AnyCancellable?

    private var bag: Set<AnyCancellable> = []

    init(
        provider: SendFeeProvider,
        defaultFeeOptions: [FeeOption],
        customFeeService: CustomFeeService?,
        predefinedAmount: Amount? = nil,
        predefinedDestination: String? = nil
    ) {
        self.provider = provider
        self.defaultFeeOptions = defaultFeeOptions
        self.customFeeService = customFeeService
        _cryptoAmount = .init(predefinedAmount)
        _destination = .init(predefinedDestination)

        bind()
    }

    func bind() {
        _fees
            .withWeakCaptureOf(self)
            .compactMap { interactor, fees in
                fees.value.flatMap { interactor.initialFeeForUpdate(fees: $0) }
            }
            // Only once
            .first()
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                interactor.initialSelectedFeeUpdateIfNeeded(fee: fee)
                fee.value.value.map {
                    interactor.customFeeService?.initialSetupCustomFee($0)
                }
            }
            .store(in: &bag)
    }

    func bind(input: any SendFeeInput) {
        cryptoAmountSubscribtion = input.cryptoAmountPublisher
            .withWeakCaptureOf(self)
            .sink { processor, amount in
                processor._cryptoAmount.send(amount)
            }

        destinationAddressSubscribtion = input.destinationAddressPublisher
            .withWeakCaptureOf(self)
            .sink { processor, destination in
                processor._destination.send(destination)
            }
    }
}

// MARK: - SendFeeInteractor

extension CommonSendFeeInteractor: SendFeeInteractor {
    var selectedFee: SendFee? {
        input?.selectedFee
    }

    func setup(input: any SendFeeInput, output: any SendFeeOutput) {
        self.input = input
        self.output = output

        bind(input: input)
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value,
              let destination = _destination.value else {
            assertionFailure("SendFeeInteractor is not ready to update fees")
            return
        }

        provider
            .getFee(amount: amount, destination: destination)
            .sink(receiveCompletion: { [weak self] completion in
                guard case .failure(let error) = completion else {
                    return
                }

                self?._fees.send(.failedToLoad(error: error))
            }, receiveValue: { [weak self] fees in
                self?._fees.send(.loaded(fees))
            })
            .store(in: &bag)
    }

    func update(selectedFee: SendFee) {
        output?.feeDidChanged(fee: selectedFee)
    }

    func selectedFeePublisher() -> AnyPublisher<SendFee?, Never> {
        input?.selectedFeePublisher ?? .just(output: nil)
    }

    func feesPublisher() -> AnyPublisher<[SendFee], Never> {
        Publishers.CombineLatest(_fees, _customFee)
            .withWeakCaptureOf(self)
            .map { interactor, args in
                let (feesValue, customFee) = args
                return interactor.mapToSendFees(feesValue: feesValue, customFee: customFee)
            }
            .eraseToAnyPublisher()
    }

    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel] {
        customFeeService?.inputFieldModels() ?? []
    }
}

// MARK: - CustomFeeServiceInput

extension CommonSendFeeInteractor: CustomFeeServiceInput {
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> {
        _cryptoAmount.compactMap { $0 }.eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String, Never> {
        _destination.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - CustomFeeServiceOutput

extension CommonSendFeeInteractor: CustomFeeServiceOutput {
    func customFeeDidChanged(_ customFee: Fee) {
        _customFee.send(customFee)
        update(selectedFee: .init(option: .custom, value: .loaded(customFee)))
        _fees.send(_fees.value)
    }
}

// MARK: - Private

private extension CommonSendFeeInteractor {
    func mapToSendFees(feesValue: LoadingValue<[Fee]>, customFee: Fee?) -> [SendFee] {
        switch feesValue {
        case .loading:
            return feeOptions.map { SendFee(option: $0, value: .loading) }
        case .loaded(let fees):
            return mapToFees(fees: fees, customFee: customFee)
        case .failedToLoad(let error):
            return feeOptions.map { SendFee(option: $0, value: .failedToLoad(error: error)) }
        }
    }

    func mapToFees(fees: [Fee], customFee: Fee?) -> [SendFee] {
        var defaultOptions = mapToDefaultFees(fees: fees)

        if supportCustomFee {
            let customFee = customFee ?? defaultOptions.first(where: { $0.option == .market })?.value.value

            if let customFee {
                defaultOptions.append(SendFee(option: .custom, value: .loaded(customFee)))
            }
        }

        return defaultOptions
    }

    func mapToDefaultFees(fees: [Fee]) -> [SendFee] {
        switch fees.count {
        case 1:
            return [SendFee(option: .market, value: .loaded(fees[0]))]
        case 3:
            return [
                SendFee(option: .slow, value: .loaded(fees[0])),
                SendFee(option: .market, value: .loaded(fees[1])),
                SendFee(option: .fast, value: .loaded(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }

    private func initialFeeForUpdate(fees: [Fee]) -> SendFee? {
        let values = mapToDefaultFees(fees: fees)
        let market = values.first(where: { $0.option == .market })
        return market
    }

    private func initialSelectedFeeUpdateIfNeeded(fee: SendFee) {
        guard input?.selectedFee == nil else {
            return
        }

        output?.feeDidChanged(fee: fee)
    }
}
