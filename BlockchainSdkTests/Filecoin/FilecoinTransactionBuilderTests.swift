//
//  FilecoinTransactionBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

final class FilecoinTransactionBuilderTests: XCTestCase {
    private let transactionBuilder: FilecoinTransactionBuilder = try! FilecoinTransactionBuilder(
        publicKey: Wallet.PublicKey(
            seedKey: Constants.publicKey,
            derivationType: nil
        )
    )
    private let sizeTester = TransactionSizeTesterUtility()
    
    private var transaction: Transaction {
        Transaction(
            amount: Amount(
                with: .filecoin,
                type: .coin,
                value: 1
            ),
            fee: Fee(
                Amount(
                    with: .filecoin,
                    type: .coin,
                    value: (100704 * 1527953) / Blockchain.filecoin.decimalValue
                ),
                parameters: FilecoinFeeParameters(
                    gasLimit: 1527953,
                    gasFeeCap: 100704,
                    gasPremium: 99503
                )
            ),
            sourceAddress: Constants.sourceAddress,
            destinationAddress: Constants.destinationAddress,
            changeAddress: Constants.sourceAddress
        )
    }
    
    func testBuildForSign() throws {
        let expected = Data(hex: "0beac3427b81d6fa6e93a05a0b64fcc3c7ce4af9d05af31ee343bcc527ae8b18")
        let actual = try transactionBuilder.buildForSign(transaction: transaction, nonce: 1)
    
        sizeTester.testTxSize(actual)
        XCTAssertEqual(expected, actual)
    }
    
    func testBuildForSend() throws {
        let nonce: UInt64 = 1
        let expected = FilecoinSignedMessage(
            message: FilecoinMessage(
                from: Constants.sourceAddress,
                to: Constants.destinationAddress,
                value: "1000000000000000000",
                nonce: nonce,
                gasLimit: 1527953,
                gasFeeCap: "100704",
                gasPremium: "99503"
            ),
            signature: FilecoinSignedMessage.Signature(
                type: 1,
                data: "weMNBBonfukL/wkGAb6z8ZM8c5Op5BuFPMvQAVZvdJkU0/HdRX+DEPV+A4x5sWKmWbZzyIgNyGhxpbD2yO3vkgA="
            )
        )
        
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction, nonce: nonce)
        
        let actual = try transactionBuilder.buildForSend(
            transaction: transaction,
            nonce: nonce,
            signatureInfo: SignatureInfo(
                signature: Constants.signature,
                publicKey: Constants.publicKey,
                hash: hashToSign
            )
        )
        
        XCTAssertEqual(expected, actual)
    }
}

private extension FilecoinTransactionBuilderTests {
    enum Constants {
        static let publicKey = Data(hex: "02a1f09e4d91756b9f1d4f96c2c71d09178e3850a70703c3d089dad84f3870b3c6")
        static let signature = Data(hex: "c1e30d041a277ee90bff090601beb3f1933c7393a9e41b853ccbd001566f749914d3f1dd457f8310f57e038c79b162a659b673c8880dc86871a5b0f6c8edef92")
                
        static let sourceAddress = "f1kub5b7ekrwn7vykavn7owjuff7kqcoa4g4fgriq"
        static let destinationAddress = "f1ufoxbvz637fkjbrk2d4cktqsgjwsqwm4woa7pda"
    }
}
