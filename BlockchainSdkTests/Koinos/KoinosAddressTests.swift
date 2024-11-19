//
//  KoinosTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 14.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore
import XCTest
@testable import BlockchainSdk

final class KoinosAddressTests: XCTestCase {
    private let addressService = KoinosAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

    func testMakeAddress1() throws {
        let publicKey = Data(hex: "03B2D98CF41E82D9B99842A1D05860A1B06532015138F9067239706E06EE38E621")
        let expectedAddress = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }

    func testMakeAddress2() throws {
        let publicKey = Data(hex: "03607ffd808bdeab4dca2605854b2ab58ed18caf9034b6f0ad38a7fab065b6a997")
        let expectedAddress = "18KSv997KjmdraZvdjfvdy6dr3nFejLrV4"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }

    func testMakeAddress3() throws {
        let publicKey = Data(hex: "030eeba48e9e8afb81322ba5ae1c79f960e3bca42534e9c7581b8b11273e46afd6")
        let expectedAddress = "1EcwHZbYn8L6C46fFyDcNNqPHzHpWu91QU"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }

    func testMakeAddress4() throws {
        let publicKey = Data(hex: "03c4beb040a7867631c6570a3204fd3cfb9039dfddd3ccab8bed3adf3c5604e8d9")
        let expectedAddress = "18zebc8669iQXQJXeweY7WpTkV7KXw1px9"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }

    func testMakeAddress5() throws {
        let publicKey = Data(hex: "03a5ce110ac3aeb610d6dcc565257af6efc43fef0801ffc2e7d37fd69befa6b4e3")
        let expectedAddress = "1P6uLkKezNTSDC3M3eiyoXSKibXpVwcmqc"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }

    func testValidateCorrectAddress1() {
        let address = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateCorrectAddress2() {
        let address = "18KSv997KjmdraZvdjfvdy6dr3nFejLrV4"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateCorrectAddress3() {
        let address = "1EcwHZbYn8L6C46fFyDcNNqPHzHpWu91QU"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateCorrectAddress4() {
        let address = "18zebc8669iQXQJXeweY7WpTkV7KXw1px9"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateCorrectAddress5() {
        let address = "1P6uLkKezNTSDC3M3eiyoXSKibXpVwcmqc"

        XCTAssertTrue(addressService.validate(address))
    }

    func testValidateIncorrectAddress1() {
        let address = "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8T"

        XCTAssertFalse(addressService.validate(address))
    }

    func testValidateIncorrectAddress2() {
        let address = "18KSv997KjmdraZvdjfvdy6dr3nFejLrV"

        XCTAssertFalse(addressService.validate(address))
    }

    func testValidateIncorrectAddress3() {
        let address = "1EcwHZbYn8L6C46fFyDcNNqPHzHpWu91Q"

        XCTAssertFalse(addressService.validate(address))
    }

    func testValidateIncorrectAddress4() {
        let address = "18zebc8669iQXQJXeweY7WpTkV7KXw1px"

        XCTAssertFalse(addressService.validate(address))
    }

    func testValidateIncorrectAddress5() {
        let address = "1P6uLkKezNTSDC3M3eiyoXSKibXpVwcmq"

        XCTAssertFalse(addressService.validate(address))
    }

    func testEdError1() {
        let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }

    func testEdError2() {
        let edKey = Data(hex: "EC55E8D3F6B9C28F37B4CFA1A87896FB10ADAD42F0FC42FA8827D58032EF0E2E")

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }

    func testEdError3() {
        let edKey = Data(hex: "7C40243D15B7343A42DB8B9D12A9B676FB28B5F5DA9B8B5CC153ED2A16222C66")

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }

    func testEdError4() {
        let edKey = Data(hex: "05A297C37A0F287E937F4B9E1F451027DD118792B75E5B930B9B20A3AD7AFA94")

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }

    func testEdError5() {
        let edKey = Data(hex: "A9FA6D0866C3B3D8F5F2B9F8D8D45C6E81B8729A93E9E2423BBAB732FA1ED9AC")

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }
}
