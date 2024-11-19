//
//  MantleTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 16.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

final class MantleTests: XCTestCase {
    private let blockchain = Blockchain.mantle(testnet: false)

    func testDecodeEncodedForSend() throws {
        let testCases: [Decimal] = [
            try XCTUnwrap(Decimal(stringValue: "29.618123086712134")),
            try XCTUnwrap(Decimal(stringValue: "0.000000000003194")),
            try XCTUnwrap(Decimal(stringValue: "84.329847293749302")),
            try XCTUnwrap(Decimal(stringValue: "19.287394872934987")),
            try XCTUnwrap(Decimal(stringValue: "73.928374982374892")),
            try XCTUnwrap(Decimal(stringValue: "1.847392874932748")),
            try XCTUnwrap(Decimal(stringValue: "47.832984723984723")),
            try XCTUnwrap(Decimal(stringValue: "0.0000000001234567")),
            try XCTUnwrap(Decimal(stringValue: "56.392847293847298")),
        ]

        try testCases.forEach { decimal in
            let amount = Amount(with: blockchain, type: .coin, value: decimal)

            let encodedForSend = try XCTUnwrap(amount.encodedForSend)
            let decodedValue = EthereumUtils.parseEthereumDecimal(encodedForSend, decimalsCount: blockchain.decimalCount)

            XCTAssertEqual(decodedValue, decimal)
        }
    }
}
