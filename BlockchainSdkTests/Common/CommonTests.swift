//
//  CommonTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 03.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemSdk
import BigInt

@testable import BlockchainSdk

class CommonTests: XCTestCase {
    func testHexStringExtensions() {
        XCTAssertTrue("0xaabbccdd".hasHexPrefix())
        XCTAssertTrue("0xAABBCC".hasHexPrefix())
        XCTAssertFalse("aabbccdd".hasHexPrefix())
        XCTAssertEqual("aabbccdd".addHexPrefix(), "0xaabbccdd")
        XCTAssertEqual("AABBCCdd".addHexPrefix(), "0xAABBCCdd")
        XCTAssertEqual("0xaabbccdd".addHexPrefix(), "0xaabbccdd")
        XCTAssertEqual("0xaabbccdd".removeHexPrefix(), "aabbccdd")
        XCTAssertEqual("0xAABBCCdd".removeHexPrefix(), "AABBCCdd")
        XCTAssertEqual("AABBCCdd".removeHexPrefix(), "AABBCCdd")
    }

    func testOverflow() {
        let max = BigUInt(18446744073709551615)
        let eth = Blockchain.ethereum(testnet: false)
        let calculated = Decimal(UInt64(max)) / eth.decimalValue
        let estimated = Decimal(string: "18.446744073709551615")
        XCTAssertEqual(calculated, estimated)
    }
}
