//
//  QRCodeParserTests.swift
//  TangemTests
//
//  Created by Andrey Chukavin on 13.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import BlockchainSdk
@testable import Tangem

final class QRCodeParserTests: XCTestCase {
    func testParser() throws {
        let parser = QRCodeParser(amountType: .coin, blockchain: .bitcoin(testnet: false))

        testPositiveCase(
            code: "bitcoin:bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=asdasd",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: Amount(with: .bitcoin(testnet: false), type: .coin, value: Decimal(1234.56789)),
            parser: parser
        )

        // negative

        testNegativeCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt61",
            amount: Amount(with: .bitcoin(testnet: false), type: .coin, value: Decimal(1334.56789)),
            parser: parser
        )
    }

    private func testPositiveCase(
        code: String,
        destination: String,
        amount: Amount?,
        parser: QRCodeParser

    ) {
        let result = parser.parse(code)
        XCTAssertEqual(result.destination, destination)
        XCTAssertEqual(result.amount?.string(), amount?.string())
    }

    private func testNegativeCase(
        code: String,
        destination: String,
        amount: Amount?,
        parser: QRCodeParser

    ) {
        let result = parser.parse(code)
        XCTAssertNotEqual(result.destination, destination)
        XCTAssertNotEqual(result.amount?.string(), amount?.string())
    }
}
