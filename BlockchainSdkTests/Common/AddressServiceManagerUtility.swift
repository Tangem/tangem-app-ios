//
//  AddressServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore
@testable import BlockchainSdk

final class AddressServiceManagerUtility {
    func makeTrustWalletAddress(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        if case .ton = blockchain {
            return try TonAddressService().makeAddress(from: publicKey).value
        } else if let coin = CoinType(blockchain) {
            return try WalletCoreAddressService(coin: coin).makeAddress(from: publicKey).value
        } else {
            throw NSError(domain: "__ AddressServiceManagerUtility __ error make address from TrustWallet address service", code: -1)
        }
    }

    func makeTangemAddress(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain,
        addressType: AddressType = .default
    ) throws -> String {
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        return try service.makeAddress(from: publicKey, type: addressType).value
    }
}
