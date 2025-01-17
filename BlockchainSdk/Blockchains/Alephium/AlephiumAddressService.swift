//
//  AlephiumAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumAddressService {}

// MARK: - AddressProvider

extension AlephiumAddressService: AddressProvider, AddressValidator {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        throw WalletError.empty
    }
    
    func validate(_ address: String) -> Bool {
        return false
    }
}
