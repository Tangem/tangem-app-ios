//
//  WalletFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletFactory {
    private let blockchain: Blockchain

    private var addressProvider: AddressProvider {
        AddressServiceFactory(blockchain: blockchain).makeAddressService()
    }

    public init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    /// With one public key
    func makeWallet(publicKey: Wallet.PublicKey) throws -> Wallet {
        let addressTypes: [AddressType] = AddressTypesConfig().types(for: blockchain)

        let addresses: [AddressType: Address] = try addressTypes.reduce(into: [:]) { result, addressType in
            result[addressType] = try addressProvider.makeAddress(for: publicKey, with: addressType)
        }

        return Wallet(blockchain: blockchain, addresses: addresses)
    }

    /// With multisig script public key
    func makeWallet(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> Wallet {
        guard let addressProvider = addressProvider as? BitcoinScriptAddressesProvider else {
            throw WalletError.empty
        }

        let addresses = try addressProvider.makeAddresses(publicKey: publicKey, pairPublicKey: pairPublicKey)

        return Wallet(
            blockchain: blockchain,
            addresses: addresses.reduce(into: [:]) { $0[$1.type] = $1 }
        )
    }
}
