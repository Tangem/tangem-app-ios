//
//  CoinAddressCompareTests.swift
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

/// Basic testplan for testing validation Addresses blockchain with compare addresses from TrustWallet address service and Local address service
class AddressesValidationTests: XCTestCase {
    let testVectorsUtility = TestVectorsUtility()

    func testAddressVector() throws {
        guard let blockchains: [BlockchainSdk.Blockchain] = try testVectorsUtility.getTestVectors(from: "blockchain_vectors") else {
            XCTFail("__INVALID_BLOCKCHAIN__ DATA IS NIL")
            return
        }

        guard let vectors: [DecodableVectors.ValidAddressVector] = try testVectorsUtility.getTestVectors(from: "valid_address_vectors") else {
            XCTFail("__INVALID_VECTOR__ ADDRESSES DATA IS NIL")
            return
        }

        try vectors.forEach { vector in
            guard let blockchain = blockchains.first(where: { $0.codingKey == vector.blockchain }) else {
                XCTFail("__INVALID_VECTOR__ MATCH BLOCKCHAIN KEY IS NIL '\(vector.blockchain)'")
                return
            }

            let coin = try XCTUnwrap(CoinType(blockchain), "__INVALID_VECTOR__ CANNOT CREATE WALLET CORE COIN FOR BLOCKCHAIN '\(blockchain.displayName)'")
            let walletCoreAddressValidator: AddressValidator

            if coin == .ton {
                walletCoreAddressValidator = TonAddressService()
            } else {
                walletCoreAddressValidator = WalletCoreAddressService(coin: coin, publicKeyType: coin.publicKeyType)
            }
            let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()

            vector.positive.forEach { vector in
                XCTAssertTrue(walletCoreAddressValidator.validate(vector), "__INVALID_ADDRESS__ WALLET CORE FAILURE -> '\(vector)' FOR BLOCKCHAIN '\(blockchain.displayName)'")
                XCTAssertTrue(addressValidator.validate(vector), "__INVALID_ADDRESS__ SDK FAILURE -> '\(vector)' FOR BLOCKCHAIN '\(blockchain.displayName)'")
            }

            vector.negative.forEach { vector in
                XCTAssertFalse(walletCoreAddressValidator.validate(vector), "__INVALID_ADDRESS__ WALLET CORE FAILURE -> '\(vector)' FOR BLOCKCHAIN '\(blockchain.displayName)'")
                XCTAssertFalse(addressValidator.validate(vector), "__INVALID_ADDRESS__ SDK FAILURE -> '\(vector)' FOR BLOCKCHAIN '\(blockchain.displayName)'")
            }
        }
    }
}
