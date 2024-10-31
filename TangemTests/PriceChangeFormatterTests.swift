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

        let result = formatter.formatFractionalValue(0.00000001, option: .priceChange)
        XCTAssertEqual(result.formattedText, "0,00 %")
        XCTAssertEqual(result.signType, .neutral)

        let result1 = formatter.formatFractionalValue(-0.00000001, option: .priceChange)
        XCTAssertEqual(result1.formattedText, "0,00 %")
        XCTAssertEqual(result1.signType, .neutral)

        let result2 = formatter.formatFractionalValue(0.0000000, option: .priceChange)
        XCTAssertEqual(result2.formattedText, "0,00 %")
        XCTAssertEqual(result2.signType, .neutral)

        let result3 = formatter.formatFractionalValue(-0.0000000, option: .priceChange)
        XCTAssertEqual(result3.formattedText, "0,00 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.formatFractionalValue(0.01, option: .priceChange)
        XCTAssertEqual(result4.formattedText, "1,00 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.formatFractionalValue(-0.01, option: .priceChange)
        XCTAssertEqual(result5.formattedText, "1,00 %")
        XCTAssertEqual(result5.signType, .negative)

        let result6 = formatter.formatFractionalValue(0, option: .priceChange)
        XCTAssertEqual(result6.formattedText, "0,00 %")
        XCTAssertEqual(result6.signType, .neutral)

        let result7 = formatter.formatFractionalValue(0.00016, option: .priceChange)
        XCTAssertEqual(result7.formattedText, "0,02 %")
        XCTAssertEqual(result7.signType, .positive)

        let result8 = formatter.formatFractionalValue(-0.00014, option: .priceChange)
        XCTAssertEqual(result8.formattedText, "0,01 %")
        XCTAssertEqual(result8.signType, .negative)

        let result9 = formatter.formatFractionalValue(0.00009, option: .priceChange)
        XCTAssertEqual(result9.formattedText, "0,01 %")
        XCTAssertEqual(result9.signType, .positive)

        let result10 = formatter.formatFractionalValue(-0.00009, option: .priceChange)
        XCTAssertEqual(result10.formattedText, "0,01 %")
        XCTAssertEqual(result10.signType, .negative)

        let result11 = formatter.formatFractionalValue(-0.0533, option: .priceChange)
        XCTAssertEqual(result11.formattedText, "5,33 %")
        XCTAssertEqual(result11.signType, .negative)

        let result12 = formatter.formatFractionalValue(0.0533, option: .priceChange)
        XCTAssertEqual(result12.formattedText, "5,33 %")
        XCTAssertEqual(result12.signType, .positive)

        let result13 = formatter.formatFractionalValue(0.00005, option: .priceChange)
        XCTAssertEqual(result13.formattedText, "0,01 %")
        XCTAssertEqual(result13.signType, .positive)

        let result14 = formatter.formatFractionalValue(-0.00001, option: .priceChange)
        XCTAssertEqual(result14.formattedText, "0,00 %")
        XCTAssertEqual(result14.signType, .neutral)
    }

    func testPriceChangeFormatterExpress() {
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "ru_RU")))

        let result = formatter.formatFractionalValue(0.00000001, option: .express)
        XCTAssertEqual(result.formattedText, "+0,0 %")
        XCTAssertEqual(result.signType, .neutral)

        let result1 = formatter.formatFractionalValue(-0.00000001, option: .express)
        XCTAssertEqual(result1.formattedText, "+0,0 %")
        XCTAssertEqual(result1.signType, .neutral)

        let result2 = formatter.formatFractionalValue(0.0000000, option: .express)
        XCTAssertEqual(result2.formattedText, "+0,0 %")
        XCTAssertEqual(result2.signType, .neutral)

        let result3 = formatter.formatFractionalValue(-0.0000000, option: .express)
        XCTAssertEqual(result3.formattedText, "+0,0 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.formatFractionalValue(0.09, option: .express)
        XCTAssertEqual(result4.formattedText, "+9,0 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.formatFractionalValue(-0.09, option: .express)
        XCTAssertEqual(result5.formattedText, "-9,0 %")
        XCTAssertEqual(result5.signType, .negative)

        let result6 = formatter.formatFractionalValue(0, option: .express)
        XCTAssertEqual(result6.formattedText, "+0,0 %")
        XCTAssertEqual(result6.signType, .neutral)

        let result7 = formatter.formatFractionalValue(0.16, option: .express)
        XCTAssertEqual(result7.formattedText, "+16,0 %")
        XCTAssertEqual(result7.signType, .positive)

        let result8 = formatter.formatFractionalValue(-0.14, option: .express)
        XCTAssertEqual(result8.formattedText, "-14,0 %")
        XCTAssertEqual(result8.signType, .negative)

        let result9 = formatter.formatFractionalValue(0.09, option: .express)
        XCTAssertEqual(result9.formattedText, "+9,0 %")
        XCTAssertEqual(result9.signType, .positive)

        let result10 = formatter.formatFractionalValue(-0.09, option: .express)
        XCTAssertEqual(result10.formattedText, "-9,0 %")
        XCTAssertEqual(result10.signType, .negative)

        let result11 = formatter.formatFractionalValue(-0.533, option: .express)
        XCTAssertEqual(result11.formattedText, "-53,3 %")
        XCTAssertEqual(result11.signType, .negative)

        let result12 = formatter.formatFractionalValue(0.001, option: .express)
        XCTAssertEqual(result12.formattedText, "+0,1 %")
        XCTAssertEqual(result12.signType, .positive)

        let result13 = formatter.formatFractionalValue(-0.0001, option: .express)
        XCTAssertEqual(result13.formattedText, "+0,0 %")
        XCTAssertEqual(result13.signType, .neutral)
    }

    func testPriceChangePercentFormatter() {
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "en_US")))

        let result = formatter.formatPercentValue(0.1, option: .priceChange)
        XCTAssertEqual(result.formattedText, "0.10 %")
        XCTAssertEqual(result.signType, .positive)

        let result1 = formatter.formatPercentValue(-10, option: .priceChange)
        XCTAssertEqual(result1.formattedText, "10.00 %")
        XCTAssertEqual(result1.signType, .negative)

        let result2 = formatter.formatPercentValue(-156.6743666, option: .priceChange)
        XCTAssertEqual(result2.formattedText, "156.67 %")
        XCTAssertEqual(result2.signType, .negative)

        let result3 = formatter.formatPercentValue(0, option: .priceChange)
        XCTAssertEqual(result3.formattedText, "0.00 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.formatPercentValue(99.999, option: .priceChange)
        XCTAssertEqual(result4.formattedText, "100.00 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.formatPercentValue(0.00001, option: .priceChange)
        XCTAssertEqual(result5.formattedText, "0.00 %")
        XCTAssertEqual(result5.signType, .neutral)

        let result6 = formatter.formatPercentValue(0.005, option: .priceChange)
        XCTAssertEqual(result6.formattedText, "0.01 %")
        XCTAssertEqual(result6.signType, .positive)
    }
}
