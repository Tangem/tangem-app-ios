//
//  SendAddressService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

// MARK: - Service protocol

protocol SendAddressService {
    var validationInProgressPublisher: AnyPublisher<Bool, Never> { get }

    func validate(address: String) async throws -> String?
    func canEmbedAdditionalField(into address: String) -> Bool
}

// MARK: - Default implementation

class DefaultSendAddressService: SendAddressService {
    private let walletAddresses: [Address]
    private let addressService: AddressService

    var validationInProgressPublisher: AnyPublisher<Bool, Never> {
        validationInProgressSubject.eraseToAnyPublisher()
    }

    private var validationInProgressSubject = CurrentValueSubject<Bool, Never>(false)

    init(walletAddresses: [Address], addressService: AddressService) {
        self.walletAddresses = walletAddresses
        self.addressService = addressService
    }

    func validate(address: String) async throws -> String? {
        validationInProgressSubject.send(true)

        defer {
            validationInProgressSubject.send(false)
        }

        if address.isEmpty {
            return nil
        }

        if walletAddresses.contains(where: { $0.value == address }) {
            throw SendAddressServiceError.sameAsWalletAddress
        }

        if !addressService.validate(address) {
            throw SendAddressServiceError.invalidAddress
        }

        return address
    }

    func canEmbedAdditionalField(into address: String) -> Bool {
        if let addressAdditionalFieldService = addressService as? AddressAdditionalFieldService {
            return addressAdditionalFieldService.canEmbedAdditionalField(into: address)
        } else {
            return false
        }
    }
}

// MARK: - Service that can resolve an address (from a user-friendly one like in NEAR protocol)

class SendResolvableAddressService: SendAddressService {
    private let defaultSendAddressService: DefaultSendAddressService
    private let addressResolver: AddressResolver

    var validationInProgressPublisher: AnyPublisher<Bool, Never> {
        validationInProgressSubject.eraseToAnyPublisher()
    }

    private var validationInProgressSubject = CurrentValueSubject<Bool, Never>(false)

    init(defaultSendAddressService: DefaultSendAddressService, addressResolver: AddressResolver) {
        self.defaultSendAddressService = defaultSendAddressService
        self.addressResolver = addressResolver
    }

    func validate(address: String) async throws -> String? {
        validationInProgressSubject.send(true)

        defer {
            validationInProgressSubject.send(false)
        }

        guard let validatedAddress = try await defaultSendAddressService.validate(address: address) else {
            return nil
        }

        do {
            let validationDebounceDelay = 1.0
            try await Task.sleep(seconds: validationDebounceDelay)

            try Task.checkCancellation()

            return try await addressResolver.resolve(validatedAddress)
        } catch {
            throw SendAddressServiceError.invalidAddress
        }
    }

    func canEmbedAdditionalField(into address: String) -> Bool {
        defaultSendAddressService.canEmbedAdditionalField(into: address)
    }
}

// MARK: - Errors

private enum SendAddressServiceError {
    case sameAsWalletAddress
    case invalidAddress
}

extension SendAddressServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .sameAsWalletAddress:
            return Localization.sendErrorAddressSameAsWallet
        case .invalidAddress:
            return Localization.sendRecipientAddressError
        }
    }
}
