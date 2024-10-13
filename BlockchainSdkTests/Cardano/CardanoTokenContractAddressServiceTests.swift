//
//  CardanoTokenContractAddressServiceTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 01.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

@testable import BlockchainSdk

class CardanoTokenContractAddressServiceTests: XCTestCase {
    /// Test cases taken from https://cips.cardano.org/cip/CIP-14
    func testValidation() {
        let validator = CardanoTokenContractAddressService()

        // WMT, AssetID
        XCTAssertTrue(validator.validate("1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1e776f726c646d6f62696c65746f6b656e"))

        // AGIX, PolicyID
        XCTAssertTrue(validator.validate("f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc535"))

        // Fingerprint
        XCTAssertTrue(validator.validate("asset1rjklcrnsdzqp65wjgrg55sy9723kw09mlgvlc3"))

        // Invalid
        XCTAssertFalse(validator.validate("f43a62fdc3965df486de8a0d32fe800963589c41b38946602a0dc53"))
    }

    func testFilter() throws {
        let converter = CardanoTokenContractAddressService()

        // policyId
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373",
                symbol: nil
            ),
            "asset1rjklcrnsdzqp65wjgrg55sy9723kw09mlgvlc3"
        )

        // policyId + assetNameHex
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373" + "504154415445",
                symbol: nil
            ),
            "asset13n25uv0yaf5kus35fm2k86cqy60z58d9xmde92"
        )

        // policyId
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc37e",
                symbol: nil
            ),
            "asset1nl0puwxmhas8fawxp8nx4e2q3wekg969n2auw3"
        )

        // policyId
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209",
                symbol: nil
            ),
            "asset1uyuxku60yqe57nusqzjx38aan3f2wq6s93f6ea"
        )

        // policyId + assetNameHex
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209" + "7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373",
                symbol: nil
            ),
            "asset1aqrdypg669jgazruv5ah07nuyqe0wxjhe2el6f"
        )

        // policyId + assetNameHex
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373" + "1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209",
                symbol: nil
            ),
            "asset17jd78wukhtrnmjh3fngzasxm8rck0l2r4hhyyt"
        )

        // policyId + assetNameHex
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "1e349c9bdea19fd6c147626a5260bc44b71635f398b67c59881df209" + "504154415445",
                symbol: nil
            ),
            "asset1hv4p5tv2a837mzqrst04d0dcptdjmluqvdx9k3"
        )

        // policyId + assetNameHex
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "7eae28af2208be856f7a119668ae52a49b73725e326dc16579dcc373" + "0000000000000000000000000000000000000000000000000000000000000000",
                symbol: nil
            ),
            "asset1pkpwyknlvul7az0xx8czhl60pyel45rpje4z8w"
        )

        // fingerprint
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "asset1pkpwyknlvul7az0xx8czhl60pyel45rpje4z8w",
                symbol: nil
            ),
            "asset1pkpwyknlvul7az0xx8czhl60pyel45rpje4z8w"
        )

        // policyId + assetName
        XCTAssertEqual(
            try converter.convertToFingerprint(
                address: "8fef2d34078659493ce161a6c7fba4b56afefa8535296a5743f69587",
                symbol: "AADA"
            ),
            "asset1khk46tdfsknze9k84ae0ee0k2x8mcwhz93k70d"
        )
    }
}
