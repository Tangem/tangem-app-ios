//
//  TONAddressService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 17.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

final class TonAddressService: AddressService {
    private let coin: CoinType = .ton
    
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        let tonAddress = try makeTheOpenNetworkAddress(for: publicKey)
        let addressString = tonAddress.stringRepresentation(userFriendly: true, bounceable: false, testOnly: false)
        return PlainAddress(value: addressString, publicKey: publicKey, type: addressType)
    }

    func validate(_ address: String) -> Bool {
        return TheOpenNetworkAddress.isValidString(string: address)
    }

    func makeTheOpenNetworkAddress(for publicKey: Wallet.PublicKey) throws -> TheOpenNetworkAddress {
        guard let walletCorePublicKey = PublicKey(tangemPublicKey: publicKey.blockchainKey, publicKeyType: coin.publicKeyType) else {
            throw WalletCoreAddressService.TWError.makeAddressFailed
        }

        return TheOpenNetworkAddress(publicKey: walletCorePublicKey)
    }
}
