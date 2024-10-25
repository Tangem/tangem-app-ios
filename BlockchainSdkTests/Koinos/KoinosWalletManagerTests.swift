//
//  KoinosWalletManagerTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 04.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import BlockchainSdk

final class KoinosWalletManagerTests: XCTestCase {
    private var walletManager: KoinosWalletManager!

    override func setUp() {
        walletManager = KoinosWalletManager(
            wallet: Wallet(
                blockchain: .koinos(testnet: false),
                addresses: [
                    .default: PlainAddress(
                        value: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                        publicKey: .init(seedKey: .init(), derivationType: nil),
                        type: .default
                    ),
                ]
            ),
            networkService: KoinosNetworkService(providers: []),
            transactionBuilder: KoinosTransactionBuilder(koinosNetworkParams: KoinosNetworkParams(isTestnet: false))
        )
    }

    override func tearDown() {
        walletManager = nil
    }

    func testTxValidationSmoke() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 100)

        XCTAssertNoThrow(
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaFee(value: 0.3)
            )
        )
    }

    func testTxValidationNotEnoughMana() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 0.2)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 10),
                fee: .manaFee(value: 0.3)
            )
            XCTFail("Expected ValidationError.insufficientFeeResource but no error was thrown")
        } catch let e as ValidationError {
            XCTAssertEqual(
                e,
                ValidationError.insufficientFeeResource(
                    type: .mana,
                    current: 20000000,
                    max: 10000000000
                )
            )
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testTxValidationAmountExceedsManaBalance() {
        walletManager.wallet.addBalance(balance: 100)
        walletManager.wallet.addMana(mana: 50)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 51),
                fee: .manaFee(value: 0.3)
            )
            XCTFail("Expected ValidationError.insufficientFeeResource but no error was thrown")
        } catch let e as ValidationError {
            XCTAssertEqual(
                e,
                ValidationError.insufficientFeeResource(
                    type: .mana,
                    current: 50 * pow(10, 8),
                    max: 100 * pow(10, 8)
                )
            )
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }

    func testTxValidationCoinBalanceDoesNotCoverFee() {
        walletManager.wallet.addBalance(balance: 0.2)
        walletManager.wallet.addMana(mana: 0.2)

        do {
            try walletManager.validate(
                amount: .coinAmount(value: 0.2),
                fee: .manaFee(value: 0.3)
            )
            XCTFail("Expected ValidationError.feeExceedsMaxFeeResource but no error was thrown")
        } catch let e as ValidationError {
            XCTAssertEqual(e, ValidationError.feeExceedsMaxFeeResource)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
}

private extension Amount {
    static let blockchain = Blockchain.koinos(testnet: false)

    static func coinAmount(value: Decimal) -> Amount {
        Amount(
            with: blockchain,
            type: .coin,
            value: value * pow(10, blockchain.decimalCount)
        )
    }

    static func manaAmount(value: Decimal) -> Amount {
        Amount(
            type: .feeResource(.mana),
            currencySymbol: FeeResourceType.mana.rawValue,
            value: value * pow(10, blockchain.decimalCount),
            decimals: blockchain.decimalCount
        )
    }
}

private extension Fee {
    static func manaFee(value: Decimal) -> Fee {
        Fee(.manaAmount(value: value))
    }
}

private extension Wallet {
    mutating func addBalance(balance: Decimal) {
        add(amount: .coinAmount(value: balance))
    }

    mutating func addMana(mana: Decimal) {
        add(
            amount: Amount(
                type: .feeResource(.mana),
                currencySymbol: FeeResourceType.mana.rawValue,
                value: mana * pow(10, blockchain.decimalCount),
                decimals: blockchain.decimalCount
            )
        )
    }
}
