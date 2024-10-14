//
//  SendDestinationInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

protocol SendDestinationInteractor {
    var transactionHistoryPublisher: AnyPublisher<[SendSuggestedDestinationTransactionRecord], Never> { get }

    var hasError: Bool { get }
    var isValidatingDestination: AnyPublisher<Bool, Never> { get }
    var canEmbedAdditionalField: AnyPublisher<Bool, Never> { get }
    var destinationValid: AnyPublisher<Bool, Never> { get }
    var allFieldsIsValid: AnyPublisher<Bool, Never> { get }
    var destinationError: AnyPublisher<String?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<String?, Never> { get }

    func update(destination: String, source: Analytics.DestinationAddressSource)
    func update(additionalField: String)
}

class CommonSendDestinationInteractor {
    private weak var input: SendDestinationInput?
    private weak var output: SendDestinationOutput?

    private let validator: SendDestinationValidator
    private let transactionHistoryProvider: SendDestinationTransactionHistoryProvider
    private let transactionHistoryMapper: TransactionHistoryMapper
    private let addressResolver: AddressResolver?
    private let additionalFieldType: SendDestinationAdditionalFieldType?
    private let parametersBuilder: SendTransactionParametersBuilder

    private let _isValidatingDestination: CurrentValueSubject<Bool, Never> = .init(false)
    private let _canEmbedAdditionalField: CurrentValueSubject<Bool, Never> = .init(true)

    private let _destinationValid: CurrentValueSubject<Bool, Never> = .init(false)
    private let _destinationError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _additionalFieldValid: CurrentValueSubject<Bool, Never> = .init(true)
    private let _destinationAdditionalFieldError: CurrentValueSubject<Error?, Never> = .init(nil)

    init(
        input: SendDestinationInput,
        output: SendDestinationOutput,
        validator: SendDestinationValidator,
        transactionHistoryProvider: SendDestinationTransactionHistoryProvider,
        transactionHistoryMapper: TransactionHistoryMapper,
        addressResolver: AddressResolver?,
        additionalFieldType: SendDestinationAdditionalFieldType?,
        parametersBuilder: SendTransactionParametersBuilder
    ) {
        self.input = input
        self.output = output
        self.validator = validator
        self.transactionHistoryProvider = transactionHistoryProvider
        self.transactionHistoryMapper = transactionHistoryMapper
        self.addressResolver = addressResolver
        self.additionalFieldType = additionalFieldType
        self.parametersBuilder = parametersBuilder
    }

    private func update(destination result: Result<String?, Error>, source: Analytics.DestinationAddressSource) {
        switch result {
        case .success(.none), .success(Constants.emptyString):
            _destinationValid.send(false)
            _destinationError.send(.none)
            output?.destinationDidChanged(.none)

        case .success(.some(let address)):
            assert(!address.isEmpty, "Had to fall in case above")

            _destinationValid.send(true)
            _destinationError.send(.none)
            Analytics.logDestinationAddress(isAddressValid: true, source: source)
            output?.destinationDidChanged(.init(value: address, source: source))

        case .failure(let error):
            _destinationValid.send(false)
            _destinationError.send(error)
            Analytics.logDestinationAddress(isAddressValid: false, source: source)
            output?.destinationDidChanged(.none)
        }
    }

    private func resolve(destination: String, resolver: AddressResolver) async throws -> String {
        _isValidatingDestination.send(true)
        let resolved = try await resolver.resolve(destination)
        _isValidatingDestination.send(false)

        return resolved
    }

    private func proceed(additionalField: String) throws -> SendDestinationAdditionalField {
        guard let type = additionalFieldType else {
            assertionFailure("Additional field for the blockchain whick doesn't support it")
            return .notSupported
        }

        guard let parameters = try parametersBuilder.transactionParameters(from: additionalField) else {
            // We don't have to call this code if transactionParameters doesn't exist fot this blockchain
            // Check your input parameters
            assertionFailure("Additional field for the blockchain whick doesn't support it")
            return .notSupported
        }

        return .filled(type: type, value: additionalField, params: parameters)
    }
}

// MARK: - SendDestinationInteractor

extension CommonSendDestinationInteractor: SendDestinationInteractor {
    var hasError: Bool {
        _destinationError.value != nil || _destinationAdditionalFieldError.value != nil
    }

    var transactionHistoryPublisher: AnyPublisher<[SendSuggestedDestinationTransactionRecord], Never> {
        transactionHistoryProvider
            .transactionHistoryPublisher
            .withWeakCaptureOf(self)
            .map { interactor, records in
                records
                    .compactMap { interactor.transactionHistoryMapper.mapSuggestedRecord($0) }
                    .prefix(Constants.numberOfRecentTransactions)
                    .sorted { $0.date > $1.date }
            }
            .eraseToAnyPublisher()
    }

    var isValidatingDestination: AnyPublisher<Bool, Never> {
        _isValidatingDestination.eraseToAnyPublisher()
    }

    var canEmbedAdditionalField: AnyPublisher<Bool, Never> {
        _canEmbedAdditionalField.eraseToAnyPublisher()
    }

    var destinationValid: AnyPublisher<Bool, Never> {
        _destinationValid.eraseToAnyPublisher()
    }

    var allFieldsIsValid: AnyPublisher<Bool, Never> {
        Publishers
            .CombineLatest(_destinationValid, _additionalFieldValid)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }

    var destinationError: AnyPublisher<String?, Never> {
        _destinationError.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    var destinationAdditionalFieldError: AnyPublisher<String?, Never> {
        _destinationAdditionalFieldError.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    func update(destination address: String, source: Analytics.DestinationAddressSource) {
        _canEmbedAdditionalField.send(validator.canEmbedAdditionalField(into: address))

        guard !address.isEmpty else {
            update(destination: .success(.none), source: source)
            return
        }

        do {
            try validator.validate(destination: address)

            if let addressResolver = addressResolver {
                runTask(in: self) { interactor in
                    do {
                        let resolved = try await interactor.resolve(destination: address, resolver: addressResolver)
                        interactor.update(destination: .success(resolved), source: source)
                    } catch {
                        interactor.update(destination: .failure(error), source: source)
                    }
                }
            } else {
                update(destination: .success(address), source: source)
            }
        } catch {
            update(destination: .failure(error), source: source)
        }
    }

    func update(additionalField value: String) {
        guard let type = additionalFieldType else {
            assertionFailure("This method doesn't be called if additionalFieldType is nil")
            output?.destinationAdditionalParametersDidChanged(.notSupported)
            _additionalFieldValid.send(true)
            return
        }

        guard !value.isEmpty else {
            output?.destinationAdditionalParametersDidChanged(.empty(type: type))
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
            return
        }

        do {
            let type = try proceed(additionalField: value)
            output?.destinationAdditionalParametersDidChanged(type)
            _destinationAdditionalFieldError.send(nil)
            _additionalFieldValid.send(true)
        } catch {
            _destinationAdditionalFieldError.send(error)
            output?.destinationAdditionalParametersDidChanged(.empty(type: type))
            _additionalFieldValid.send(false)
        }
    }
}

private extension CommonSendDestinationInteractor {
    enum Constants {
        static let numberOfRecentTransactions = 10
        static let emptyString = ""
    }
}
