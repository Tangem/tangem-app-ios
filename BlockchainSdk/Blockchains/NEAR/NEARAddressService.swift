//
//  NEARAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class NEARAddressService {
    private lazy var walletCoreAddressService = WalletCoreAddressService(coin: .near)
}

// MARK: - AddressProvider protocol conformance

extension NEARAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        return try walletCoreAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator protocol conformance

extension NEARAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        if NEARAddressUtil.isImplicitAccount(accountId: address) {
            return walletCoreAddressService.validate(address)
        }

        return NEARAddressUtil.isValidNamedAccount(accountId: address)
    }
}
