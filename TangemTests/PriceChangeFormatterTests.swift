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

        let result = formatter.format(0.00000001, option: .priceChange)
        XCTAssertEqual(result.formattedText, "0,00 %")
        XCTAssertEqual(result.signType, .neutral)

        let result1 = formatter.format(-0.00000001, option: .priceChange)
        XCTAssertEqual(result1.formattedText, "0,00 %")
        XCTAssertEqual(result1.signType, .neutral)

        let result2 = formatter.format(0.0000000, option: .priceChange)
        XCTAssertEqual(result2.formattedText, "0,00 %")
        XCTAssertEqual(result2.signType, .neutral)

        let result3 = formatter.format(-0.0000000, option: .priceChange)
        XCTAssertEqual(result3.formattedText, "0,00 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.format(0.01, option: .priceChange)
        XCTAssertEqual(result4.formattedText, "1,00 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.format(-0.01, option: .priceChange)
        XCTAssertEqual(result5.formattedText, "1,00 %")
        XCTAssertEqual(result5.signType, .negative)

        let result6 = formatter.format(0, option: .priceChange)
        XCTAssertEqual(result6.formattedText, "0,00 %")
        XCTAssertEqual(result6.signType, .neutral)

        let result7 = formatter.format(0.00016, option: .priceChange)
        XCTAssertEqual(result7.formattedText, "0,02 %")
        XCTAssertEqual(result7.signType, .positive)

        let result8 = formatter.format(-0.00014, option: .priceChange)
        XCTAssertEqual(result8.formattedText, "0,01 %")
        XCTAssertEqual(result8.signType, .negative)

        let result9 = formatter.format(0.00009, option: .priceChange)
        XCTAssertEqual(result9.formattedText, "0,01 %")
        XCTAssertEqual(result9.signType, .positive)

        let result10 = formatter.format(-0.00009, option: .priceChange)
        XCTAssertEqual(result10.formattedText, "0,01 %")
        XCTAssertEqual(result10.signType, .negative)

        let result11 = formatter.format(-0.0533, option: .priceChange)
        XCTAssertEqual(result11.formattedText, "5,33 %")
        XCTAssertEqual(result11.signType, .negative)

        let result12 = formatter.format(0.0533, option: .priceChange)
        XCTAssertEqual(result12.formattedText, "5,33 %")
        XCTAssertEqual(result12.signType, .positive)

        let result13 = formatter.format(0.00005, option: .priceChange)
        XCTAssertEqual(result13.formattedText, "0,01 %")
        XCTAssertEqual(result13.signType, .positive)

        let result14 = formatter.format(-0.00001, option: .priceChange)
        XCTAssertEqual(result14.formattedText, "0,00 %")
        XCTAssertEqual(result14.signType, .neutral)
    }

    func testPriceChangeFormatterExpress() {
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "ru_RU")))

        let result = formatter.format(0.00000001, option: .express)
        XCTAssertEqual(result.formattedText, "0,0 %")
        XCTAssertEqual(result.signType, .neutral)

        let result1 = formatter.format(-0.00000001, option: .express)
        XCTAssertEqual(result1.formattedText, "0,0 %")
        XCTAssertEqual(result1.signType, .neutral)

        let result2 = formatter.format(0.0000000, option: .express)
        XCTAssertEqual(result2.formattedText, "0,0 %")
        XCTAssertEqual(result2.signType, .neutral)

        let result3 = formatter.format(-0.0000000, option: .express)
        XCTAssertEqual(result3.formattedText, "0,0 %")
        XCTAssertEqual(result3.signType, .neutral)

        let result4 = formatter.format(0.09, option: .express)
        XCTAssertEqual(result4.formattedText, "9,0 %")
        XCTAssertEqual(result4.signType, .positive)

        let result5 = formatter.format(-0.09, option: .express)
        XCTAssertEqual(result5.formattedText, "-9,0 %")
        XCTAssertEqual(result5.signType, .negative)

        let result6 = formatter.format(0, option: .express)
        XCTAssertEqual(result6.formattedText, "0,0 %")
        XCTAssertEqual(result6.signType, .neutral)

        let result7 = formatter.format(0.16, option: .express)
        XCTAssertEqual(result7.formattedText, "16,0 %")
        XCTAssertEqual(result7.signType, .positive)

        let result8 = formatter.format(-0.14, option: .express)
        XCTAssertEqual(result8.formattedText, "-14,0 %")
        XCTAssertEqual(result8.signType, .negative)

        let result9 = formatter.format(0.09, option: .express)
        XCTAssertEqual(result9.formattedText, "9,0 %")
        XCTAssertEqual(result9.signType, .positive)

        let result10 = formatter.format(-0.09, option: .express)
        XCTAssertEqual(result10.formattedText, "-9,0 %")
        XCTAssertEqual(result10.signType, .negative)

        let result11 = formatter.format(-0.533, option: .express)
        XCTAssertEqual(result11.formattedText, "-53,3 %")
        XCTAssertEqual(result11.signType, .negative)

        let result12 = formatter.format(0.001, option: .express)
        XCTAssertEqual(result12.formattedText, "0,1 %")
        XCTAssertEqual(result12.signType, .positive)

        let result13 = formatter.format(-0.0001, option: .express)
        XCTAssertEqual(result13.formattedText, "0,0 %")
        XCTAssertEqual(result13.signType, .neutral)
    }
}
