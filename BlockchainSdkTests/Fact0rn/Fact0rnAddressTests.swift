//
//  Fact0rnAddressTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore
import XCTest
@testable import BlockchainSdk

final class Fact0rnAddressTests: XCTestCase {
    private let addressService = Fact0rnAddressService()

    func testAddressFromCorrectPublicKey() throws {
        let walletPublicKey = try XCTUnwrap(Data(hexString: "03B6D7E1FB0977A5881A3B1F64F9778B4F56CB2B9EFD6E0D03E60051EAFEBF5831"))
        let expectedAddress = "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey"

        let address = try addressService.makeAddress(from: walletPublicKey)

        XCTAssertEqual(address.value, expectedAddress)
    }

    func testScriptHashFromAddress() throws {
        let address = "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey"
        let expectedScriptHash = "808171256649754B402099695833B95E4507019B3E494A7DBC6F62058F09050E".lowercased()

        let scriptHash = try Fact0rnAddressService.addressToScriptHash(address: address)

        XCTAssertEqual(scriptHash.lowercased(), expectedScriptHash)
    }
}
