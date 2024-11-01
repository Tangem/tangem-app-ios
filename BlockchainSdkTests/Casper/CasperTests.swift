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

    // MARK: - Properties

    let PUBLIC_KEY = "03ae9bdc765678be0ef74c3845f1f506fa8dbbef7a57aaa39a40daafc13dc9ac60"
    let SIGNATURE = "020d735191dbc378a30d9c122384bf77169d165d0123ce16c31cf3d86cb213aa1b26842d9e204f0c2c5f6719f1371fd9710d01b766bd724a099c45305fae776185"
    let SOURCE_ADDRESS = "0203ae9bdc765678be0ef74c3845f1f506fa8dbbef7a57aaa39a40daafc13dc9ac60"
    let DESTINATION_ADDRESS = "0198c07d7e72d89a681d7227a7af8a6fd5f22fe0105c8741d55a95df415454b82e"
    let TIMESTAMP = "2024-10-12T12:04:41.031Z"

    // MARK: - Address Tests

    func testMakeAddressFromCorrectEd25519PublicKey() throws {
        let walletPublicKey = Data(hexString: "98C07D7E72D89A681D7227A7AF8A6FD5F22FE0105C8741D55A95DF415454B82E")
        let expectedAddress = "0198c07D7e72D89A681d7227a7Af8A6fd5F22fe0105c8741d55A95dF415454b82E"

        let addressService = CasperAddressService(curve: .ed25519)

        try XCTAssertEqual(addressService.makeAddress(from: walletPublicKey).value, expectedAddress)
    }

    func testValidateCorrectEd25519Address() {
        let address = "0198c07D7e72D89A681d7227a7Af8A6fd5F22fe0105c8741d55A95dF415454b82E"

        let addressService = CasperAddressService(curve: .ed25519)

        XCTAssertTrue(addressService.validate(address))
    }

    func testMakeAddressFromCorrectSecp256k1PublicKey() {
        let walletPublicKey = Data(hexString: "021F997DFBBFD32817C0E110EAEE26BCBD2BB70B4640C515D9721C9664312EACD8")
        let expectedAddress = "02021f997DfbbFd32817C0E110EAeE26BCbD2BB70b4640C515D9721c9664312eaCd8"

        let addressService = CasperAddressService(curve: .secp256k1)

        try XCTAssertEqual(addressService.makeAddress(from: walletPublicKey).value, expectedAddress)
    }

    func testValidateCorrectSecp256k1Address() {
        let address = "02021f997DfbbFd32817C0E110EAeE26BCbD2BB70b4640C515D9721c9664312eaCd8"

        let addressService = CasperAddressService(curve: .secp256k1)

        XCTAssertTrue(addressService.validate(address))
    }

    // MARK: - Transaction Tests

    func testBuildTransaction() throws {
        let txBuilder = CasperTransactionBuilder(blockchain: blockchain)
        let transferAmount = Amount(with: blockchain, value: 2.5)
        let feeAmount = Amount(with: blockchain, value: 0.1)

        let transaction = Transaction(
            amount: transferAmount,
            fee: Fee(feeAmount),
            sourceAddress: SOURCE_ADDRESS,
            destinationAddress: DESTINATION_ADDRESS,
            changeAddress: SOURCE_ADDRESS
        )

        do {
            let hashForSign = try txBuilder.buildForSign(transaction: transaction, timestamp: TIMESTAMP)
            print(hashForSign.hexString)
        } catch {
            print(error)
        }
    }
}
