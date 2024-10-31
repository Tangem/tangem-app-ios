//
//  DecimalExtensionsTests.swift
//  TangemTests
//
//  Created by Andrey Fedorov on 28.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import Tangem

final class DecimalExtensionsTests: XCTestCase {
    func testSimpleDecimalNumber() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "123.456"))
        XCTAssertEqual(decimalValue.scale, 3, "Scale should be 3 for 123.456")
    }

    func testDecimalNumberWithTrailingZeros() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "123.45000"))
        XCTAssertEqual(decimalValue.scale, 2, "Scale should be 2 for 123.45000")
    }

    func testWholeNumber() throws {
        let decimalValue: Decimal = 12345 // `ExpressibleByIntegerLiteral` maintains required precision, unlike `ExpressibleByFloatLiteral`
        XCTAssertEqual(decimalValue.scale, 0, "Scale should be 0 for 12345")
    }

    func testWholeNumberWithDecimalPoint() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "456.0"))
        XCTAssertEqual(decimalValue.scale, 0, "Scale should be 0 for 456.0")
    }

    func testSmallDecimalNumber() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "0.000123"))
        XCTAssertEqual(decimalValue.scale, 6, "Scale should be 6 for 0.000123")
    }

    func testLargeDecimalNumber() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "123456789.123456789"))
        XCTAssertEqual(decimalValue.scale, 9, "Scale should be 9 for 123456789.123456789")
    }

    func testDecimalWithLargeExponent() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "1.23456789E+9"))
        XCTAssertEqual(decimalValue.scale, 0, "Scale should be 0 for 1.23456789E+9")
    }

    func testNegativeDecimalNumber() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "-123.456"))
        XCTAssertEqual(decimalValue.scale, 3, "Scale should be 3 for -123.456")
    }

    func testNegativeDecimalWithTrailingZeros() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "-123.45000"))
        XCTAssertEqual(decimalValue.scale, 2, "Scale should be 2 for -123.45000")
    }

    func testSmallestPositiveDecimalNumber() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "0.00000000000000000001"))
        XCTAssertEqual(decimalValue.scale, 20, "Scale should be 20 for 0.00000000000000000001")
    }

    func testDecimalWithExponentNoFractionalPart() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "1.23E+5"))
        XCTAssertEqual(decimalValue.scale, 0, "Scale should be 0 for 1.23E+5")
    }

    func testDecimalWithMultipleLeadingZeros() throws {
        let decimalValue = try XCTUnwrap(Decimal(stringValue: "0.00000123"))
        XCTAssertEqual(decimalValue.scale, 8, "Scale should be 8 for 0.00000123")
    }
}
