//
//  PriceChangeFormatterTests.swift
//  TangemTests
//
//  Created by Alexander Osokin on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class PriceChangeFormatterTests: XCTestCase {
    func testPriceChangeFormatter() {
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "ru_RU")))

        let result = formatter.format(value: 0.00000001)
        XCTAssertEqual(result.formattedText, "0,00 %")
        XCTAssertEqual(result.signType, .neutral)

        let result1 = formatter.format(value: -0.00000001)
        XCTAssertEqual(result1.formattedText, "0,00 %")
        XCTAssertEqual(result1.signType, .neutral)

        let result2 = formatter.format(value: 0.0000000)
        XCTAssertEqual(result2.formattedText, "0,00 %")
        XCTAssertEqual(result2.signType, .neutral)

        let result3 = formatter.format(value: -0.0000000)
        XCTAssertEqual(result3.formattedText, "0,00 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.format(value: 0.01)
        XCTAssertEqual(result4.formattedText, "0,01 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.format(value: -0.01)
        XCTAssertEqual(result5.formattedText, "0,01 %")
        XCTAssertEqual(result5.signType, .negative)

        let result6 = formatter.format(value: 0)
        XCTAssertEqual(result6.formattedText, "0,00 %")
        XCTAssertEqual(result6.signType, .neutral)

        let result7 = formatter.format(value: 0.016)
        XCTAssertEqual(result7.formattedText, "0,02 %")
        XCTAssertEqual(result7.signType, .positive)

        let result8 = formatter.format(value: -0.014)
        XCTAssertEqual(result8.formattedText, "0,01 %")
        XCTAssertEqual(result8.signType, .negative)

        let result9 = formatter.format(value: 0.009)
        XCTAssertEqual(result9.formattedText, "0,01 %")
        XCTAssertEqual(result9.signType, .positive)

        let result10 = formatter.format(value: -0.009)
        XCTAssertEqual(result10.formattedText, "0,01 %")
        XCTAssertEqual(result10.signType, .negative)

        let result11 = formatter.format(value: -5.33)
        XCTAssertEqual(result11.formattedText, "5,33 %")
        XCTAssertEqual(result11.signType, .negative)

        let result12 = formatter.format(value: 0.005)
        XCTAssertEqual(result12.formattedText, "0,01 %")
        XCTAssertEqual(result12.signType, .positive)

        let result13 = formatter.format(value: -0.001)
        XCTAssertEqual(result13.formattedText, "0,00 %")
        XCTAssertEqual(result13.signType, .neutral)
    }

    func testPriceChangeFormatterExpress() {
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "ru_RU")))

        let result = formatter.formatExpress(value: 0.00000001)
        XCTAssertEqual(result.formattedText, "0,0 %")
        XCTAssertEqual(result.signType, .neutral)

        let result1 = formatter.formatExpress(value: -0.00000001)
        XCTAssertEqual(result1.formattedText, "0,0 %")
        XCTAssertEqual(result1.signType, .neutral)

        let result2 = formatter.formatExpress(value: 0.0000000)
        XCTAssertEqual(result2.formattedText, "0,0 %")
        XCTAssertEqual(result2.signType, .neutral)

        let result3 = formatter.formatExpress(value: -0.0000000)
        XCTAssertEqual(result3.formattedText, "0,0 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.formatExpress(value: 0.09)
        XCTAssertEqual(result4.formattedText, "9,0 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.formatExpress(value: -0.09)
        XCTAssertEqual(result5.formattedText, "-9,0 %")
        XCTAssertEqual(result5.signType, .negative)

        let result6 = formatter.formatExpress(value: 0)
        XCTAssertEqual(result6.formattedText, "0,0 %")
        XCTAssertEqual(result6.signType, .neutral)

        let result7 = formatter.formatExpress(value: 0.16)
        XCTAssertEqual(result7.formattedText, "16,0 %")
        XCTAssertEqual(result7.signType, .positive)

        let result8 = formatter.formatExpress(value: -0.14)
        XCTAssertEqual(result8.formattedText, "-14,0 %")
        XCTAssertEqual(result8.signType, .negative)

        let result9 = formatter.formatExpress(value: 0.09)
        XCTAssertEqual(result9.formattedText, "9,0 %")
        XCTAssertEqual(result9.signType, .positive)

        let result10 = formatter.formatExpress(value: -0.09)
        XCTAssertEqual(result10.formattedText, "-9,0 %")
        XCTAssertEqual(result10.signType, .negative)

        let result11 = formatter.formatExpress(value: -0.533)
        XCTAssertEqual(result11.formattedText, "-53,3 %")
        XCTAssertEqual(result11.signType, .negative)

        let result12 = formatter.formatExpress(value: 0.001)
        XCTAssertEqual(result12.formattedText, "0,1 %")
        XCTAssertEqual(result12.signType, .positive)

        let result13 = formatter.formatExpress(value: -0.0001)
        XCTAssertEqual(result13.formattedText, "0,0 %")
        XCTAssertEqual(result13.signType, .neutral)
    }
}

