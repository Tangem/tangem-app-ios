//
// SuiAddressService.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 27.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

final class SuiAddressService: AddressService {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        try WalletCoreAddressService(coin: .sui).makeAddress(for: publicKey, with: .default)
    }

    func validate(_ address: String) -> Bool {
        WalletCoreAddressService(coin: .sui).validate(address)
    }
}
