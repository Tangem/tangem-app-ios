//
//  KoinosTransactionBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 21.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk
import WalletCore
import XCTest
@testable import BlockchainSdk

final class KoinosTransactionBuilderTests: XCTestCase {
    private let transactionBuilder = KoinosTransactionBuilder(koinosNetworkParams: KoinosNetworkParams(isTestnet: false))
    private let transactionBuilderTestnet = KoinosTransactionBuilder(koinosNetworkParams: KoinosNetworkParams(isTestnet: true))
    
    // MARK: Mainnet
    
    private var expectedTransaction: KoinosProtocol.Transaction {
        KoinosProtocol.Transaction(
            header: KoinosProtocol.TransactionHeader(
                chainId: "EiBZK_GGVP0H_fXVAM3j6EAuz3-B-l3ejxRSewi7qIBfSA==",
                rcLimit: "500000000",
                nonce: "KAs=",
                operationMerkleRoot: "EiBd86ETLP-Tmmq-Oj6wxfe1o2KzRGf_9LV-9O3_9Qmu8w==",
                payer: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                payee: nil
            ),
            id: "0x12201042aeee64fcc89921d0b5f9bdd6c9bff3e9c089d3579c74882fe0f018acd608",
            operations: [
                KoinosProtocol.Operation(
                    callContract: KoinosProtocol.CallContractOperation(
                        contractId: "15DJN4a8SgrbGhhGksSBASiSYjGnMU8dGL",
                        entryPoint: 670398154,
                        args: "ChkAaMW2_tO2QuoaSAiMXztphDRhY2m4f6efEhkAaEFbbHucCFnoEOh3RgGrOZ38TNTI9xMWGICYmrwE"
                    )
                )
            ],
            signatures: []
        )
    }
    
    private var expectedHash: Data {
        "1042AEEE64FCC89921D0B5F9BDD6C9BFF3E9C089D3579C74882FE0F018ACD608".data(using: .hexadecimal)!
    }
    
    private var expectedSignature: String {
        "Hxeh6xzso62xaxeutW30BRJyC3mu_OGEwWJt1n5e8Ugjc0Cfj2cxVzY7JjxgspGu2Nq9MLbr8c0-lY64FKwj_pQ="
    }
    
    
    // MARK: Testnet
    
    private var expectedTransactionTestnet: KoinosProtocol.Transaction {
        KoinosProtocol.Transaction(
            header: KoinosProtocol.TransactionHeader(
                chainId: "EiBncD4pKRIQWco_WRqo5Q-xnXR7JuO3PtZv983mKdKHSQ==",
                rcLimit: "500000000",
                nonce: "KAs=",
                operationMerkleRoot: "EiCjvMCnYVk5GqAaz7D2e8LCbaJ6448pJMXS4LI_EjtW4Q==",
                payer: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
                payee: nil
            ),
            id: "0x1220f90ab33fcd0fa5896bb56352875eb49ac984cfd347467a50fe7a28686b11bb45",
            operations: [
                KoinosProtocol.Operation(
                    callContract: KoinosProtocol.CallContractOperation(
                        contractId: "1FaSvLjQJsCJKq5ybmGsMMQs8RQYyVv8ju",
                        entryPoint: 670398154,
                        args: "ChkAaMW2_tO2QuoaSAiMXztphDRhY2m4f6efEhkAaEFbbHucCFnoEOh3RgGrOZ38TNTI9xMWGICYmrwE"
                    )
                )
            ],
            signatures: []
        )
    }
    
    private var expectedHashTestnet: Data {
        "F90AB33FCD0FA5896BB56352875EB49AC984CFD347467A50FE7A28686B11BB45".data(using: .hexadecimal)!
    }
    
    
    // MARK: Factory
    
    private func makeTransaction(isTestnet: Bool) -> Transaction {
        Transaction(
            amount: Amount(with: .koinos(testnet: isTestnet), type: .coin, value: 12),
            fee: Fee(Amount.zeroCoin(for: .koinos(testnet: isTestnet))),
            sourceAddress: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
            destinationAddress: "1AWFa3VVwa2C54EU18NUDDYxjsPDwxKAuB",
            changeAddress: "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
            params: KoinosTransactionParams(manaLimit: 5)
        )
    }
}

// MARK: Tests
extension KoinosTransactionBuilderTests {
    func testBuildForSign() throws {
        let (transaction, hash) = try transactionBuilder.buildForSign(
            transaction: makeTransaction(isTestnet: false),
            currentNonce: KoinosAccountNonce(nonce: 10)
        )
        
        XCTAssertEqual(hash, expectedHash)
        XCTAssertEqual(transaction, expectedTransaction)
    }
    
    func testBuildForSignTestnet() throws {
        let (transaction, hash) = try transactionBuilderTestnet.buildForSign(
            transaction: makeTransaction(isTestnet: true),
            currentNonce: KoinosAccountNonce(nonce: 10)
        )
        
        XCTAssertEqual(hash, expectedHashTestnet)
        XCTAssertEqual(transaction, expectedTransactionTestnet)
    }
    
    func testBuildForSend() throws {
        let signature = "17A1EB1CECA3ADB16B17AEB56DF40512720B79AEFCE184C1626DD67E5EF1482373409F8F673157363B263C60B291AED8DABD30B6EBF1CD3E958EB814AC23FE94"
        let publicKey = "0350413909F40AAE7DD6A084A32017E5A45089FB29E91BBE47D41E29C32355BFCD"
        let hash = "E5E8126605ECCD2B1AAC084E8D7A6D7C708C9CE9E63AF4D1371EE7E2C2BFB339"
        
        let signedTransaction = try transactionBuilder.buildForSend(
            transaction: expectedTransaction,
            signature: SignatureInfo(
                signature: XCTUnwrap(signature.data(using: .hexadecimal)),
                publicKey: XCTUnwrap(publicKey.data(using: .hexadecimal)),
                hash: XCTUnwrap(hash.data(using: .hexadecimal))
            )
        )
        
        XCTAssertEqual(signedTransaction.signatures.count, 1)
        XCTAssertEqual(signedTransaction.signatures[0], expectedSignature)
    }
}
