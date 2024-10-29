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
}
