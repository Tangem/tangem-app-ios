//
//  SendCryptoValueFormatterTests.swift
//  TangemTests
//
//  Created by Andrey Chukavin on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class SendCryptoValueFormatterTests: XCTestCase {
    func testUSLocale() {
        let standardFormatter = SendCryptoValueFormatter(
            decimals: 30,
            currencySymbol: "NEAR",
            trimFractions: false,
            locale: Locale(identifier: "en_US")
        )
        let trimmedFractionsFormatter = SendCryptoValueFormatter(
            decimals: 30,
            currencySymbol: "NEAR",
            trimFractions: true,
            locale: Locale(identifier: "en_US")
        )

        let testData = [
            (value: Decimal(string: "1")!, expectedStandardResult: "NEAR 1.00", expectedTrimmedFractionsResult: "NEAR 1"),
            (value: Decimal(string: "2.1")!, expectedStandardResult: "NEAR 2.10", expectedTrimmedFractionsResult: "NEAR 2.1"),
            (value: Decimal(string: "3.21")!, expectedStandardResult: "NEAR 3.21", expectedTrimmedFractionsResult: "NEAR 3.21"),
            (value: Decimal(string: "4.321")!, expectedStandardResult: "NEAR 4.321", expectedTrimmedFractionsResult: "NEAR 4.321"),
            (value: Decimal(string: "0.012345678901234567890123456789")!, expectedStandardResult: "NEAR 0.012345678901234567890123456789", expectedTrimmedFractionsResult: "NEAR 0.012345678901234567890123456789"),
            (value: Decimal(string: "12345.012345678901234567890123456789")!, expectedStandardResult: "NEAR 12,345.012345678901234567890123456789", expectedTrimmedFractionsResult: "NEAR 12,345.012345678901234567890123456789"),
        ]

        testData.forEach { value, expectedStandardResult, expectedTrimmedFractionsResult in
            let standardResult = standardFormatter.string(from: value)!
            XCTAssertEqual(standardResult, expectedStandardResult)

            let trimmedFractionsResult = trimmedFractionsFormatter.string(from: value)!
            XCTAssertEqual(trimmedFractionsResult, expectedTrimmedFractionsResult)
        }
    }

    func testRULocale() {
        let standardFormatter = SendCryptoValueFormatter(
            decimals: 30,
            currencySymbol: "NEAR",
            trimFractions: false,
            locale: Locale(identifier: "ru_RU")
        )
        let trimmedFractionsFormatter = SendCryptoValueFormatter(
            decimals: 30,
            currencySymbol: "NEAR",
            trimFractions: true,
            locale: Locale(identifier: "ru_RU")
        )

        let testData = [
            (value: Decimal(string: "1")!, expectedStandardResult: "1,00 NEAR", expectedTrimmedFractionsResult: "1 NEAR"),
            (value: Decimal(string: "2.1")!, expectedStandardResult: "2,10 NEAR", expectedTrimmedFractionsResult: "2,1 NEAR"),
            (value: Decimal(string: "3.21")!, expectedStandardResult: "3,21 NEAR", expectedTrimmedFractionsResult: "3,21 NEAR"),
            (value: Decimal(string: "4.321")!, expectedStandardResult: "4,321 NEAR", expectedTrimmedFractionsResult: "4,321 NEAR"),
            (value: Decimal(string: "0.012345678901234567890123456789")!, expectedStandardResult: "0,012345678901234567890123456789 NEAR", expectedTrimmedFractionsResult: "0,012345678901234567890123456789 NEAR"),
            (value: Decimal(string: "12345.012345678901234567890123456789")!, expectedStandardResult: "12 345,012345678901234567890123456789 NEAR", expectedTrimmedFractionsResult: "12 345,012345678901234567890123456789 NEAR"),
        ]

        testData.forEach { value, expectedStandardResult, expectedTrimmedFractionsResult in
            let standardResult = standardFormatter.string(from: value)!
            XCTAssertEqual(standardResult, expectedStandardResult)

            let trimmedFractionsResult = trimmedFractionsFormatter.string(from: value)!
            XCTAssertEqual(trimmedFractionsResult, expectedTrimmedFractionsResult)
        }
    }
}
