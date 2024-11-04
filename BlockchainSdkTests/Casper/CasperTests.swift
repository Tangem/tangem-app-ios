//
//  CasperTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
@testable import BlockchainSdk

final class CasperTests: XCTestCase {
    private let blockchain = Blockchain.casper(testnet: false)

    // MARK: - Private Properties

    private let secp256k1PublicKey = "03ae9bdc765678be0ef74c3845f1f506fa8dbbef7a57aaa39a40daafc13dc9ac60"
    private let secp256k1Signature = "020d735191dbc378a30d9c122384bf77169d165d0123ce16c31cf3d86cb213aa1b26842d9e204f0c2c5f6719f1371fd9710d01b766bd724a099c45305fae776185"
    private let sourceAddress = "0203ae9bdc765678be0ef74c3845f1f506fa8dbbef7a57aaa39a40daafc13dc9ac60"
    private let destinationAddress = "0198c07d7e72d89a681d7227a7af8a6fd5f22fe0105c8741d55a95df415454b82e"
    private let timestamp = "2024-10-12T12:04:41.031Z"

    // MARK: - Transaction Tests

    func testBuildForSign() throws {
        let txBuilder = CasperTransactionBuilder(blockchain: blockchain, curve: .secp256k1)
        let transferAmount = Amount(with: blockchain, value: 2.5)
        let feeAmount = Amount(with: blockchain, value: 0.1)

        let transaction = Transaction(
            amount: transferAmount,
            fee: Fee(feeAmount),
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress
        )

        let hashForSign = try txBuilder.buildForSign(transaction: transaction, timestamp: timestamp)
        XCTAssertEqual(hashForSign.hexString.lowercased(), "951f30645f15e5955750d7aa3b50cadd8ca4044f46aa49cfe389d90825f8122f")
    }
}
