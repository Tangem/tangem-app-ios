//
//  QRCodeParserTests.swift
//  TangemTests
//
//  Created by Andrey Chukavin on 13.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.Amount
import struct BlockchainSdk.Token
@testable import Tangem

final class QRCodeParserTests: XCTestCase {
    func testBIP0021() throws {
        let blockchain: Blockchain = .bitcoin(testnet: false)
        let parser = QRCodeParser(
            amountType: .coin,
            blockchain: blockchain,
            decimalCount: blockchain.decimalCount
        )

        // MARK: - Destination address

        testPositiveCase(
            code: "bitcoin:bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "some_garbage=bitcoin:bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // MARK: - Amount

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=asdasd",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // '.' decimal separator
        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: Amount(with: blockchain, type: .coin, value: try XCTUnwrap(Decimal(stringValue: "1234.56789"))),
            memo: nil,
            parser: parser
        )

        // ',' decimal separator
        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234,56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: Amount(with: blockchain, type: .coin, value: try XCTUnwrap(Decimal(stringValue: "1234.56789"))),
            memo: nil,
            parser: parser
        )

        // We don't support mixed decimal separators and digit group separators like '1,234,567.89' or '1.234.567,89'
        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1.234,56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // We don't support mixed decimal separators and digit group separators like '1,234,567.89' or '1.234.567,89'
        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1,234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // MARK: - Message

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&memo=a%20random%20memo",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: "a random memo",
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&message=some%20message",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: "some message",
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&message=hello",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            memo: "hello",
            parser: parser
        )

        // MARK: - Negative cases

        testNegativeCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt61",
            amount: Amount(with: blockchain, type: .coin, value: try XCTUnwrap(Decimal(stringValue: "1334.56789"))),
            memo: "no memo",
            parser: parser
        )
    }

    func testERC681Coin() throws {
        let blockchain: Blockchain = .ethereum(testnet: false)
        let parser = QRCodeParser(
            amountType: .coin,
            blockchain: blockchain,
            decimalCount: blockchain.decimalCount
        )

        // MARK: - Destination address

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:pay-0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "some_garbage=ethereum:0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7/transfer?address=0xc00f86ab93cd0bd3a60213583d0fe35aaa1ace23",
            destination: nil, // the contract address doesn't match (since it's a coin, not a token), therefore the parsed destination should be nil
            amount: nil,
            memo: nil,
            parser: parser
        )

        // MARK: - Amount

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&amount=asdasd",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // '.' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1.88e10",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .coin,
                value: try XCTUnwrap(Decimal(stringValue: "0.0000000188")) //  = 1.88 * 10^10 / 10^18, 18 is the number of decimals for Ethereum
            ),
            memo: nil,
            parser: parser
        )

        // ',' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1,88e10",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .coin,
                value: try XCTUnwrap(Decimal(stringValue: "0.0000000188")) //  = 1.88 * 10^10 / 10^18, 18 is the number of decimals for Ethereum
            ),
            memo: nil,
            parser: parser
        )

        // '.' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1.68E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .coin,
                value: try XCTUnwrap(Decimal(stringValue: "0.000000168")) //  = 1.68 * 10^11 / 10^18, 18 is the number of decimals for Ethereum
            ),
            memo: nil,
            parser: parser
        )

        // ',' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1,68E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .coin,
                value: try XCTUnwrap(Decimal(stringValue: "0.000000168")) //  = 1.68 * 10^11 / 10^18, 18 is the number of decimals for Ethereum
            ),
            memo: nil,
            parser: parser
        )

        // We don't support mixed decimal separators and digit group separators like '1,234,567.89' or '1.234.567,89'
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1.222,91E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // We don't support mixed decimal separators and digit group separators like '1,234,567.89' or '1.234.567,89'
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1,222.91E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=23000000000",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .coin,
                value: try XCTUnwrap(Decimal(stringValue: "0.000000023")) //  = 23000000000 / 10^18, 18 is the number of decimals for Ethereum
            ),
            memo: nil,
            parser: parser
        )

        // MARK: - Message

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&memo=a%20random%20memo",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: "a random memo",
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&message=some%20message",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: "some message",
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&message=hello",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: "hello",
            parser: parser
        )

        // MARK: - Negative cases

        testNegativeCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&amount=1234.56789",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aCb",
            amount: Amount(with: blockchain, type: .coin, value: try XCTUnwrap(Decimal(stringValue: "1334.56789"))),
            memo: "no memo",
            parser: parser
        )
    }

    func testERC681Token() throws {
        let blockchain: Blockchain = .ethereum(testnet: false)
        let exampleToken = Token(
            name: "Test",
            symbol: "TEST",
            contractAddress: "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7",
            decimalCount: 7
        )
        let parser = QRCodeParser(
            amountType: .token(value: exampleToken),
            blockchain: blockchain,
            decimalCount: exampleToken.decimalCount
        )

        // MARK: - Destination address

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:pay-0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "some_garbage=ethereum:0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7/transfer?address=0xc00f86ab93cd0bd3a60213583d0fe35aaa1ace23",
            destination: "0xc00f86ab93cd0bd3a60213583d0fe35aaa1ace23",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // MARK: - Amount

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&amount=asdasd",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // '.' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1.88e10",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .token(value: exampleToken),
                value: try XCTUnwrap(Decimal(stringValue: "1880")) //  = 1.88 * 10^10 / 10^7, 7 is the number of decimals for `exampleToken`
            ),
            memo: nil,
            parser: parser
        )

        // ',' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1,88e10",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .token(value: exampleToken),
                value: try XCTUnwrap(Decimal(stringValue: "1880")) //  = 1.88 * 10^10 / 10^7, 7 is the number of decimals for `exampleToken`
            ),
            memo: nil,
            parser: parser
        )

        // '.' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1.68E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .token(value: exampleToken),
                value: try XCTUnwrap(Decimal(stringValue: "16800")) //  = 1.68 * 10^11 / 10^7, 7 is the number of decimals for `exampleToken`
            ),
            memo: nil,
            parser: parser
        )

        // ',' decimal separator
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1,68E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .token(value: exampleToken),
                value: try XCTUnwrap(Decimal(stringValue: "16800")) //  = 1.68 * 10^11 / 10^7, 7 is the number of decimals for `exampleToken`
            ),
            memo: nil,
            parser: parser
        )

        // We don't support mixed decimal separators and digit group separators like '1,234,567.89' or '1.234.567,89'
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1.222,91E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        // We don't support mixed decimal separators and digit group separators like '1,234,567.89' or '1.234.567,89'
        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=1,222.91E11",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&value=23000000000",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: Amount(
                with: blockchain,
                type: .token(value: exampleToken),
                value: try XCTUnwrap(Decimal(stringValue: "2300")) //  = 23000000000 / 10^7, 7 is the number of decimals for `exampleToken`
            ),
            memo: nil,
            parser: parser
        )

        // MARK: - Message

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&memo=a%20random%20memo",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: "a random memo",
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&message=some%20message",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: "some message",
            parser: parser
        )

        testPositiveCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&message=hello",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: "hello",
            parser: parser
        )

        // MARK: - Negative cases

        testNegativeCase(
            code: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb?someArgument=someValue&amount=1234.56789",
            destination: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aCb",
            amount: Amount(with: blockchain, type: .token(value: exampleToken), value: try XCTUnwrap(Decimal(stringValue: "1334.56789"))),
            memo: "no memo",
            parser: parser
        )

        testPositiveCase(
            code: "ethereum:0x6090a6e47849629b7245dfa1ca21d94cd15878ef/transfer?address=0xc00f86ab93cd0bd3a60213583d0fe35aaa1ace23",
            destination: nil,
            amount: nil,
            memo: nil,
            parser: parser
        )
    }

    private func testPositiveCase(
        code: String,
        destination: String?,
        amount: Amount?,
        memo: String?,
        parser: QRCodeParser,
        message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = parser.parse(code)
        XCTAssertEqual(result?.destination, destination, message(), file: file, line: line)
        XCTAssertEqual(result?.amount?.string(), amount?.string(), message(), file: file, line: line)
        XCTAssertEqual(result?.memo, memo, message(), file: file, line: line)
    }

    private func testNegativeCase(
        code: String,
        destination: String,
        amount: Amount?,
        memo: String?,
        parser: QRCodeParser,
        message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = parser.parse(code)
        XCTAssertNotEqual(result?.destination, destination, message(), file: file, line: line)
        XCTAssertNotEqual(result?.amount?.string(), amount?.string(), message(), file: file, line: line)
        XCTAssertNotEqual(result?.memo, memo, message(), file: file, line: line)
    }
}
