//
//  FilecoinAddressTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 25.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

final class FilecoinAddressTests: XCTestCase {
    private let addressService = WalletCoreAddressService(blockchain: .filecoin)

    func testMakeAddress() throws {
        let publicKey = Data(hex: "038A3F02BEBAFD04C1FA82184BA3950C801015A0B61A0922110D7CEE42A2A13763")
        let expectedAddress = "f1hbyibpq4mea6l3no7aag24hxpwgf4zwp6msepwi"

        XCTAssertEqual(try addressService.makeAddress(from: publicKey).value, expectedAddress)
    }
}
