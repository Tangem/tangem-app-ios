//
//  DefaultAmountNotationFormatterTests.swift
//  TangemTests
//
//  Created by Andrew Son on 12/08/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class DefaultAmountNotationFormatterTests: XCTestCase {
    private let thousandValue = Decimal(1_987)
    private let tenThousandValue = Decimal(10_987)
    private let hundredThousandValue = Decimal(190_000)
    private let millionValue = Decimal(123_543_643)
    private let billionValue = Decimal(75_548_643_234)
    private let trillionValue = Decimal(998_879_524_973_125)

    func testFormatterCurrencySymbolPositionFlag() {
        // USA
        let usFormatter = DefaultAmountNotationFormatter(locale: .init(identifier: "en_US"))
        XCTAssertTrue(usFormatter.isWithLeadingCurrencySymbol)

        // Russia
        let ruFormatter = DefaultAmountNotationFormatter(locale: .init(identifier: "ru_RU"))
        XCTAssertFalse(ruFormatter.isWithLeadingCurrencySymbol)

        // Switzerland
        let chFormatted = DefaultAmountNotationFormatter(locale: .init(identifier: "de_CH"))
        XCTAssertTrue(chFormatted.isWithLeadingCurrencySymbol)

        // United Kingdom
        let gbFormatter = DefaultAmountNotationFormatter(locale: .init(identifier: "en_GB"))
        XCTAssertTrue(gbFormatter.isWithLeadingCurrencySymbol)

        // Bulgaria
        let bgFormatter = DefaultAmountNotationFormatter(locale: .init(identifier: "ru_BG"))
        XCTAssertFalse(bgFormatter.isWithLeadingCurrencySymbol)

        // Germany
        let deFormatter = DefaultAmountNotationFormatter(locale: .init(identifier: "de_DE"))
        XCTAssertFalse(deFormatter.isWithLeadingCurrencySymbol)

        // Denmark
        let dkFormatter = DefaultAmountNotationFormatter(locale: .init(identifier: "da_DK"))
        XCTAssertFalse(dkFormatter.isWithLeadingCurrencySymbol)
    }

    func testFormatWithNotationFormatterLeadingSymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "en_US"))
        let notationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let fiatFormatter = fiatNumberFormatter(currencyCode: "USD")

        // Fiat USD

        let formattedThousand = formatter.format(
            thousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedThousand, "$1,987")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTenThousand, "$10,987")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedHundredThousands, "$190K")

        let formattedMillion = formatter.format(
            millionValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedMillion, "$123.54M")

        let formattedBillion = formatter.format(
            billionValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedBillion, "$75.55B")

        let formattedTrillion = formatter.format(
            trillionValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTrillion, "$998.88T")

        // Crypto
        let cryptoFormatter = cryptoNumberFormatter(currencyCode: "USDT")

        let formattedThousandUSDT = formatter.format(
            thousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedThousandUSDT, "USDT 1,987")

        let formattedTenThousandUSDT = formatter.format(
            tenThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTenThousandUSDT, "USDT 10,987")

        let formattedHundredThousandsUSDT = formatter.format(
            hundredThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedHundredThousandsUSDT, "USDT 190K")

        let formattedMillionUSDT = formatter.format(
            millionValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedMillionUSDT, "USDT 123.54M")

        let formattedBillionUSDT = formatter.format(
            billionValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedBillionUSDT, "USDT 75.55B")

        let formattedTrillionUSDT = formatter.format(
            trillionValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTrillionUSDT, "USDT 998.88T")
    }

    func testFormatWithNotationFormatterTrailingSymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "de_DE"))
        let notationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)

        // Fiat USD
        let fiatFormatter = fiatNumberFormatter(currencyCode: "EUR")

        let formattedThousand = formatter.format(
            thousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedThousand, "1,987 €")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTenThousand, "10,987 €")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedHundredThousands, "190K €")

        let formattedMillion = formatter.format(
            millionValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedMillion, "123.54M €")

        let formattedBillion = formatter.format(
            billionValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedBillion, "75.55B €")

        let formattedTrillion = formatter.format(
            trillionValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTrillion, "998.88T €")

        // Crypto
        let cryptoFormatter = cryptoNumberFormatter(currencyCode: "USDT")

        let formattedThousandUSDT = formatter.format(
            thousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedThousandUSDT, "1,987 USDT")

        let formattedTenThousandUSDT = formatter.format(
            tenThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTenThousandUSDT, "10,987 USDT")

        let formattedHundredThousandsUSDT = formatter.format(
            hundredThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedHundredThousandsUSDT, "190K USDT")

        let formattedMillionUSDT = formatter.format(
            millionValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedMillionUSDT, "123.54M USDT")

        let formattedBillionUSDT = formatter.format(
            billionValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedBillionUSDT, "75.55B USDT")

        let formattedTrillionUSDT = formatter.format(
            trillionValue,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(formattedTrillionUSDT, "998.88T USDT")
    }

    func testSystemFormatWithLeadingSymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "en_US"))
        let precision = NumberFormatStyleConfiguration.Precision.fractionLength(0 ... 2)

        // Fiat USD
        let fiatFormatter = fiatNumberFormatter(currencyCode: "USD")

        let formattedThousand = formatter.format(
            thousandValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedThousand, "$1.99K")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTenThousand, "$10.99K")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedHundredThousands, "$190K")

        let formattedMillion = formatter.format(
            millionValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedMillion, "$123.54M")

        let formattedBillion = formatter.format(
            billionValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedBillion, "$75.55B")

        let formattedTrillion = formatter.format(
            trillionValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTrillion, "$998.88T")

        // Crypto
        let cryptoFormatter = cryptoNumberFormatter(currencyCode: "USDT")

        let formattedThousandUSDT = formatter.format(
            thousandValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedThousandUSDT, "USDT 1.99K")

        let formattedTenThousandUSDT = formatter.format(
            tenThousandValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTenThousandUSDT, "USDT 10.99K")

        let formattedHundredThousandsUSDT = formatter.format(
            hundredThousandValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedHundredThousandsUSDT, "USDT 190K")

        let formattedMillionUSDT = formatter.format(
            millionValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedMillionUSDT, "USDT 123.54M")

        let formattedBillionUSDT = formatter.format(
            billionValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedBillionUSDT, "USDT 75.55B")

        let formattedTrillionUSDT = formatter.format(
            trillionValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTrillionUSDT, "USDT 998.88T")
    }

    func testSystemFormatWithTrailingSymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "de_DE"))
        let precision = NumberFormatStyleConfiguration.Precision.fractionLength(0 ... 2)

        // Fiat USD
        let fiatFormatter = fiatNumberFormatter(currencyCode: "EUR")

        let formattedThousand = formatter.format(
            thousandValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedThousand, "1.99K €")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTenThousand, "10.99K €")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedHundredThousands, "190K €")

        let formattedMillion = formatter.format(
            millionValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedMillion, "123.54M €")

        let formattedBillion = formatter.format(
            billionValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedBillion, "75.55B €")

        let formattedTrillion = formatter.format(
            trillionValue,
            precision: precision,
            currencySymbol: fiatFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTrillion, "998.88T €")

        // Crypto
        let cryptoFormatter = cryptoNumberFormatter(currencyCode: "USDT")

        let formattedThousandUSDT = formatter.format(
            thousandValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedThousandUSDT, "1.99K USDT")

        let formattedTenThousandUSDT = formatter.format(
            tenThousandValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTenThousandUSDT, "10.99K USDT")

        let formattedHundredThousandsUSDT = formatter.format(
            hundredThousandValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedHundredThousandsUSDT, "190K USDT")

        let formattedMillionUSDT = formatter.format(
            millionValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedMillionUSDT, "123.54M USDT")

        let formattedBillionUSDT = formatter.format(
            billionValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedBillionUSDT, "75.55B USDT")

        let formattedTrillionUSDT = formatter.format(
            trillionValue,
            precision: precision,
            currencySymbol: cryptoFormatter.currencySymbol
        )
        XCTAssertEqual(formattedTrillionUSDT, "998.88T USDT")
    }

    func testNilDecimal() {
        let formatter = DefaultAmountNotationFormatter()
        let notationFormatter = AmountNotationSuffixFormatter()
        let fiatFormatter = fiatNumberFormatter(currencyCode: "USD")
        let cryptoFormatter = cryptoNumberFormatter(currencyCode: "USDT")

        let emptyValue = formatter.defaultEmptyValue

        let fiatValueWithNotationFormatter = formatter.format(
            nil,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(fiatValueWithNotationFormatter, emptyValue)

        let cryptoValueWithNotationFormatter = formatter.format(
            nil,
            notationFormatter: notationFormatter,
            numberFormatter: cryptoFormatter,
            addingSignPrefix: false
        )
        XCTAssertEqual(cryptoValueWithNotationFormatter, emptyValue)

        let valueWithSystemFormatter = formatter.format(nil, precision: .fractionLength(0 ... 2), currencySymbol: "USD")
        XCTAssertEqual(valueWithSystemFormatter, emptyValue)
    }

    func testFormatterWithoutCurrencySymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "de_DE"))
        let precision = NumberFormatStyleConfiguration.Precision.fractionLength(0 ... 2)

        // Fiat USD

        let formattedThousand = formatter.format(
            thousandValue,
            precision: precision,
            currencySymbol: ""
        )
        XCTAssertEqual(formattedThousand, "1.99K")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            precision: precision,
            currencySymbol: ""
        )
        XCTAssertEqual(formattedTenThousand, "10.99K")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            precision: precision,
            currencySymbol: ""
        )
        XCTAssertEqual(formattedHundredThousands, "190K")

        let formattedMillion = formatter.format(
            millionValue,
            precision: precision,
            currencySymbol: ""
        )
        XCTAssertEqual(formattedMillion, "123.54M")

        let formattedBillion = formatter.format(
            billionValue,
            precision: precision,
            currencySymbol: ""
        )
        XCTAssertEqual(formattedBillion, "75.55B")

        let formattedTrillion = formatter.format(
            trillionValue,
            precision: precision,
            currencySymbol: ""
        )
        XCTAssertEqual(formattedTrillion, "998.88T")
    }

    func testSignPrefixWithTrailingSymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "de_DE"))
        let notationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)

        // Fiat USD
        let fiatFormatter = fiatNumberFormatter(currencyCode: "EUR")

        let formattedThousand = formatter.format(
            thousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedThousand, "+1,987 €")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedTenThousand, "+10,987 €")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedHundredThousands, "+190K €")

        let formattedMillion = formatter.format(
            millionValue * -1,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedMillion, "-123.54M €")

        let formattedBillion = formatter.format(
            billionValue * -1,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedBillion, "-75.55B €")

        let formattedTrillion = formatter.format(
            trillionValue * -1,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedTrillion, "-998.88T €")
    }

    func testSignPrefixWithLeadingSymbol() {
        let formatter = DefaultAmountNotationFormatter(locale: .init(identifier: "en_US"))
        let notationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)
        let fiatFormatter = fiatNumberFormatter(currencyCode: "USD")

        // Fiat USD

        let formattedThousand = formatter.format(
            thousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedThousand, "+$1,987")

        let formattedTenThousand = formatter.format(
            tenThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedTenThousand, "+$10,987")

        let formattedHundredThousands = formatter.format(
            hundredThousandValue,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedHundredThousands, "+$190K")

        let formattedMillion = formatter.format(
            millionValue * -1,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedMillion, "-$123.54M")

        let formattedBillion = formatter.format(
            billionValue * -1,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedBillion, "-$75.55B")

        let formattedTrillion = formatter.format(
            trillionValue * -1,
            notationFormatter: notationFormatter,
            numberFormatter: fiatFormatter,
            addingSignPrefix: true
        )
        XCTAssertEqual(formattedTrillion, "-$998.88T")
    }
}

extension DefaultAmountNotationFormatterTests {
    private func fiatNumberFormatter(currencyCode: String) -> NumberFormatter {
        let options = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
        let numberFormatter = BalanceFormatter().buildDefaultFiatFormatter(for: currencyCode, formattingOptions: options)
        return numberFormatter
    }

    private func cryptoNumberFormatter(currencyCode: String) -> NumberFormatter {
        let options = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
        return BalanceFormatter().buildDefaultCryptoFormatter(for: currencyCode, formattingOptions: options)
    }
}
