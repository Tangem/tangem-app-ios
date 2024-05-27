//
//  TangemTests.swift
//  TangemTests
//
//  Created by Alexander Osokin on 15.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import XCTest
import TangemSdk
@testable import Tangem

class TangemTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseConfig() throws {
        XCTAssertNoThrow(try CommonKeysManager())
    }

    func testDemoCardIds() throws {
        let cardIdRegex = try! NSRegularExpression(pattern: "[A-Z]{2}\\d{14}")
        for demoCardId in DemoUtil().demoCardIds {
            let range = NSRange(location: 0, length: demoCardId.count)
            let match = cardIdRegex.firstMatch(in: demoCardId, options: [], range: range)
            XCTAssertTrue(match != nil, "Demo Card ID \(demoCardId) is invalid")
        }
    }

    func testSignificantFractionDigitRounder() throws {
        let roundingMode: NSDecimalNumber.RoundingMode = .down

        let pairs: [(Double, Double)] = [
            (0.00, 0.00),
            (0.00000001, 0.00000001),
            (0.00002345, 0.00002),
            (0.000029, 0.00002),
            (0.000000000000000001, 0.000000000000000001),
            (0.0000000000000000001, 0.00),
            (1.00002345, 1.00),
            (1.45002345, 1.45),
        ]

        let rounder = SignificantFractionDigitRounder(roundingMode: roundingMode)

        for (value, expectedValue) in pairs {
            let roundedValue = rounder.round(value: Decimal(floatLiteral: value))
            let roundedDoubleValue = NSDecimalNumber(decimal: roundedValue).doubleValue
            XCTAssertEqual(roundedDoubleValue, expectedValue, accuracy: 0.000000000000000001)
        }
    }

    func testExpressPendingTransactionRecordMigration() throws {
        let legacyRec =
            """
            {
              "sourceTokenTxInfo": {
                "isCustom": false,
                "amountString": "0.1234132",
                "tokenItem": {
                  "blockchain": {
                    "_0": {
                      "testnet": false,
                      "key": "tezos",
                      "curve": "ed25519_slip0010"
                    }
                  }
                },
                "blockchainNetwork": {
                  "blockchain": {
                    "curve": "ed25519_slip0010",
                    "testnet": false,
                    "key": "tezos"
                  },
                  "derivationPath": "m/44'/0"
                }
              },
              "transactionType": "swap",
              "provider": {
                "type": "cex",
                "id": "asdfadf",
                "name": "asdfadf"
              },
              "feeString": "afadf",
              "date": 729430967.809831,
              "transactionHash": "afasdf",
              "transactionStatus": "confirming",
              "expressTransactionId": "Adfasdfasd",
              "userWalletId": "adfadfasdf",
              "isHidden": false,
              "externalTxId": "adfadf",
              "destinationTokenTxInfo": {
                "amountString": "0.1234132",
                "blockchainNetwork": {
                  "derivationPath": "m/44'/0",
                  "blockchain": {
                    "key": "ethereum",
                    "testnet": false,
                    "curve": "secp256k1"
                  }
                },
                "isCustom": false,
                "tokenItem": {
                  "token": {
                    "_1": {
                      "curve": "secp256k1",
                      "testnet": false,
                      "key": "ethereum"
                    },
                    "_0": {
                      "name": "Name",
                      "contractAddress": "ox124123412341234",
                      "decimalCount": 18,
                      "symbol": "SYM"
                    }
                  }
                }
              }
            }
            """

        let decoded = try JSONDecoder().decode(ExpressPendingTransactionRecord.self, from: legacyRec.data(using: .utf8)!)
        XCTAssertEqual(decoded.sourceTokenTxInfo.tokenItem.blockchainNetwork.blockchain.networkId, "tezos")
        XCTAssertEqual(decoded.destinationTokenTxInfo.tokenItem.blockchainNetwork.blockchain.networkId, "ethereum")
        XCTAssertEqual(decoded.sourceTokenTxInfo.tokenItem.blockchainNetwork.derivationPath?.rawPath, "m/44'/0")
        XCTAssertEqual(decoded.destinationTokenTxInfo.tokenItem.blockchainNetwork.derivationPath?.rawPath, "m/44'/0")
    }

    func testPriceChangeFormatter() {
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "en_US")))

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
        let formatter = PriceChangeFormatter(percentFormatter: .init(locale: .init(identifier: "en_US")))

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
