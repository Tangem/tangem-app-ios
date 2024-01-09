//
//  SendAddressService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

// MARK: - Service protocol

protocol SendAddressService {
    func validate(address: String) async throws -> String?
}

// MARK: - Default implementation

class DefaultSendAddressService: SendAddressService {
    private let walletAddresses: [Address]
    private let addressService: AddressService

    init(walletAddresses: [Address], addressService: AddressService) {
        self.walletAddresses = walletAddresses
        self.addressService = addressService
    }

    func validate(address: String) async throws -> String? {
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
}

// MARK: - Service that can resolve an address (from a user-friendly one like in NEAR protocol)

class SendResolvableAddressService: SendAddressService {
    private let defaultSendAddressService: DefaultSendAddressService
    private let addressResolver: AddressResolver

    init(defaultSendAddressService: DefaultSendAddressService, addressResolver: AddressResolver) {
        self.defaultSendAddressService = defaultSendAddressService
        self.addressResolver = addressResolver
    }

    func validate(address: String) async throws -> String? {
        guard let validatedAddress = try await defaultSendAddressService.validate(address: address) else {
            return nil
        }

        do {
            return try await addressResolver.resolve(validatedAddress)
        } catch {
            throw SendAddressServiceError.invalidAddress
        }
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
