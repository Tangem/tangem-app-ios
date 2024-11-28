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

protocol SendFeeLoader {
    func updateFees()
}

protocol SendFeeInteractor: SendFeeLoader {
    var selectedFee: SendFee? { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }

    var feesPublisher: AnyPublisher<[SendFee], Never> { get }
    var customFeeInputFieldModels: [SendCustomFeeInputFieldModel] { get }

    func update(selectedFee: SendFee)
}

class CommonSendFeeInteractor {
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?

    private let provider: SendFeeProvider
    private let customFeeService: CustomFeeService?

    private let _cryptoAmount: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private let _destination: CurrentValueSubject<String?, Never> = .init(nil)
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
        input: SendFeeInput,
        output: SendFeeOutput,
        provider: SendFeeProvider,
        defaultFeeOptions: [FeeOption],
        customFeeService: CustomFeeService?
    ) {
        self.input = input
        self.output = output
        self.provider = provider
        self.defaultFeeOptions = defaultFeeOptions
        self.customFeeService = customFeeService

        bind()
        bind(input: input)
    }

    func bind() {
        let suggestedFeeToUse = _fees
            .withWeakCaptureOf(self)
            .compactMap { interactor, fees in
                switch fees {
                case .loaded(let fees):
                    return interactor.feeForAutoupdate(fees: fees)
                case .failedToLoad(let error):
                    return SendFee(option: .market, value: .failedToLoad(error: error))
                case .loading where interactor.input?.selectedFee.value.value == nil:
                    // Show skeleton if currently fee don't have value
                    return SendFee(option: .market, value: .loading)
                case .loading:
                    // Do nothing to exclude jumping skeleton/value
                    return nil
                }
            }
            .share()

        suggestedFeeToUse
            // Only once when the fee has value
            .first(where: { $0.value.value != nil })
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                fee.value.value.map {
                    interactor.customFeeService?.initialSetupCustomFee($0)
                }
            }
            .store(in: &bag)

        suggestedFeeToUse
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                interactor.autoupdateSelectedFee(fee: fee)
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

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedFeePublisher
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        Publishers.CombineLatest(_fees, _customFee)
            .withWeakCaptureOf(self)
            .map { interactor, args in
                let (feesValue, customFee) = args
                return interactor.mapToSendFees(feesValue: feesValue, customFee: customFee)
            }
            .eraseToAnyPublisher()
    }

    var customFeeInputFieldModels: [SendCustomFeeInputFieldModel] {
        customFeeService?.inputFieldModels() ?? []
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value,
              let destination = _destination.value else {
            assertionFailure("SendFeeInteractor is not ready to update fees")
            return
        }

        provider
            .getFee(amount: amount, destination: destination)
            .mapToResult()
            .withWeakCaptureOf(self)
            .sink { interactor, result in
                switch result {
                case .success(let fees):
                    interactor._fees.send(.loaded(fees))
                case .failure(let error):
                    interactor._fees.send(.failedToLoad(error: error))
                }
            }
            .store(in: &bag)
    }

    func update(selectedFee: SendFee) {
        output?.feeDidChanged(fee: selectedFee)
    }
}

// MARK: - CustomFeeServiceInput

extension CommonSendFeeInteractor: CustomFeeServiceInput {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> {
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
            let fees = [
                SendFee(option: .slow, value: .loaded(fees[0])),
                SendFee(option: .market, value: .loaded(fees[1])),
                SendFee(option: .fast, value: .loaded(fees[2])),
            ]

            // This filter hides the values if we have not passed the default values
            return fees.filter { defaultFeeOptions.contains($0.option) }
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }

    private func feeForAutoupdate(fees: [Fee]) -> SendFee? {
        let values = mapToDefaultFees(fees: fees)
        let option = input?.selectedFee.option ?? .market
        let market = values.first(where: { $0.option == option })
        return market
    }

    private func autoupdateSelectedFee(fee: SendFee) {
        output?.feeDidChanged(fee: fee)
    }
}
