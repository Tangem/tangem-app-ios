//
//  PolkadotAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 26.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

struct PolkadotAddressService {
    private let network: PolkadotNetwork
    
    init(network: PolkadotNetwork) {
        self.network = network
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension PolkadotAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsEdKey()
        let address = PolkadotAddress(publicKey: publicKey.blockchainKey, network: network).string

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension PolkadotAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        PolkadotAddress(string: address, network: network) != nil
    }
}
