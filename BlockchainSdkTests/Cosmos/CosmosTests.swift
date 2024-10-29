//
//  CosmosTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import WalletCore
@testable import BlockchainSdk

class CosmosTests: XCTestCase {
    // From TrustWallet
    func testTransaction() throws {
        let cosmosChain = CosmosChain.gaia
        let blockchain = cosmosChain.blockchain

        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data

        let publicKey: BlockchainSdk.Wallet.PublicKey = .init(seedKey: publicKeyData, derivationType: .none)
        let address = try WalletCoreAddressService(blockchain: blockchain).makeAddress(for: publicKey, with: .default)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        let txBuilder = try CosmosTransactionBuilder(publicKey: wallet.publicKey.blockchainKey, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(8)

        let transaction = Transaction(
            amount: Amount(with: cosmosChain.blockchain, value: 0.000001),
            fee: Fee(Amount(with: cosmosChain.blockchain, value: 0.000200), parameters: CosmosFeeParameters(gas: 200_000)),
            sourceAddress: wallet.address,
            destinationAddress: "cosmos1zt50azupanqlfam5afhv3hexwyutnukeh4c573",
            changeAddress: wallet.address
        )

        let dataForSign = try txBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hexString.lowercased(), "8a6e6f74625fd39707843360120874853cc0c1d730b087f3939f4b187c75b907")

        let signature = try XCTUnwrap(privateKey.sign(digest: dataForSign, curve: cosmosChain.coin.curve))
        XCTAssertEqual(signature.hexString.lowercased(), "f9e1f4001657a42009c4eb6859625d2e41e961fc72efd2842909c898e439fc1f549916e4ecac676ee353c7d54c5ae30a29b4210b8bff0ebfdcb375e105002f4701")

        let transactionData = try txBuilder.buildForSend(
            transaction: transaction,
            signature: signature
        )

        let transactionString = try XCTUnwrap(String(data: transactionData, encoding: .utf8))

        let expectedOutput = "{\"tx_bytes\": \"CowBCokBChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEmkKLWNvc21vczFoc2s2anJ5eXFqZmhwNWRoYzU1dGM5anRja3lneDBlcGg2ZGQwMhItY29zbW9zMXp0NTBhenVwYW5xbGZhbTVhZmh2M2hleHd5dXRudWtlaDRjNTczGgkKBG11b24SATESZQpQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohAlcobsPzfTNVe7uqAAsndErJAjqplnyudaGB0f+R+p3FEgQKAggBGAgSEQoLCgRtdW9uEgMyMDAQwJoMGkD54fQAFlekIAnE62hZYl0uQelh/HLv0oQpCciY5Dn8H1SZFuTsrGdu41PH1Uxa4woptCELi/8Ov9yzdeEFAC9H\", \"mode\": \"BROADCAST_MODE_SYNC\"}"
        XCTAssertJSONEqual(transactionString, expectedOutput)
    }

    func testTerraV1Transaction() throws {
        let cosmosChain = CosmosChain.terraV1
        let blockchain = cosmosChain.blockchain

        let privateKey = PrivateKey(data: Data(hexString: "1037f828ca313f4c9e120316e8e9ff25e17f07fe66ba557d5bc5e2eeb7cba8f6"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data

        let publicKey: BlockchainSdk.Wallet.PublicKey = .init(seedKey: publicKeyData, derivationType: .none)
        let address = try WalletCoreAddressService(blockchain: blockchain).makeAddress(for: publicKey, with: .default)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        let txBuilder = try CosmosTransactionBuilder(publicKey: wallet.publicKey.blockchainKey, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(158)
        txBuilder.setSequenceNumber(0)

        let transaction = Transaction(
            amount: Amount(with: cosmosChain.blockchain, value: 1),
            fee: Fee(Amount(with: cosmosChain.blockchain, value: 0.003), parameters: CosmosFeeParameters(gas: 200_000)),
            sourceAddress: wallet.address,
            destinationAddress: "terra1hdp298kaz0eezpgl6scsykxljrje3667d233ms",
            changeAddress: wallet.address
        )

        let dataForSign = try txBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hexString.lowercased(), "8f5d74ec7f6fcbe71fc97b8926e3aca92b454913df8cbcbc5f41878333687ed5")

        let signature = try XCTUnwrap(privateKey.sign(digest: dataForSign, curve: cosmosChain.coin.curve))
        XCTAssertEqual(signature.hexString.lowercased(), "b0d8dd24b5bbd4a438f6d82e467ce4d984da98e8cd8652f475012e63134491316a548b1589576236b181bcc21945984907bfeeb8a30c39e0883184a8b640988500")

        let transactionData = try txBuilder.buildForSend(transaction: transaction, signature: signature)
        let transactionString = try XCTUnwrap(String(data: transactionData, encoding: .utf8))

        let expectedOutput =
            """
                {"mode":"BROADCAST_MODE_SYNC","tx_bytes":"CpEBCo4BChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEm4KLHRlcnJhMWpmOWFhajlteXJ6c25tcGRyN3R3ZWNuYWZ0em1rdTJtaHMyaGZlEix0ZXJyYTFoZHAyOThrYXowZWV6cGdsNnNjc3lreGxqcmplMzY2N2QyMzNtcxoQCgV1bHVuYRIHMTAwMDAwMBJlCk4KRgofL2Nvc21vcy5jcnlwdG8uc2VjcDI1NmsxLlB1YktleRIjCiEDXfGFVmUh1qeAIxnuBuGijpe3dy37X90Tym8FdVGJaOQSBAoCCAESEwoNCgV1bHVuYRIEMzAwMBDAmgwaQLDY3SS1u9SkOPbYLkZ85NmE2pjozYZS9HUBLmMTRJExalSLFYlXYjaxgbzCGUWYSQe/7rijDDngiDGEqLZAmIU="}
            """

        XCTAssertJSONEqual(transactionString, expectedOutput)
    }

    func testTerraV1USDTransaction() throws {
        let cosmosChain = CosmosChain.terraV1
        let blockchain = cosmosChain.blockchain
        let token = Token(name: "USTC", symbol: "USTC", contractAddress: "uusd", decimalCount: 6)

        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data

        let publicKey: BlockchainSdk.Wallet.PublicKey = .init(seedKey: publicKeyData, derivationType: .none)
        let address = try WalletCoreAddressService(blockchain: blockchain).makeAddress(for: publicKey, with: .default)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        let txBuilder = try CosmosTransactionBuilder(publicKey: wallet.publicKey.blockchainKey, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(1)

        let transaction = Transaction(
            amount: Amount(with: token, value: 1),
            fee: Fee(Amount(with: cosmosChain.blockchain, value: 0.03), parameters: CosmosFeeParameters(gas: 200_000)),
            sourceAddress: wallet.address,
            destinationAddress: "terra1jlgaqy9nvn2hf5t2sra9ycz8s77wnf9l0kmgcp",
            changeAddress: wallet.address
        )

        let dataForSign = try txBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hexString.lowercased(), "c8ba915f54f148a2e0feaa4d5d0ee2af558ab73ad115621b7148cb2850cbc00d")

        let signature = try XCTUnwrap(privateKey.sign(digest: dataForSign, curve: cosmosChain.coin.curve))
        XCTAssertEqual(signature.hexString.lowercased(), "271779f928eb7cfc63f6a1ed256492886529a78c0cbb043a4da18df984fe704f5b1612dcd5559560c4f15fb1d79f25be499c5251709b562fa4e77bf0c2379c2200")

        let transactionData = try txBuilder.buildForSend(transaction: transaction, signature: signature)
        let transactionString = try XCTUnwrap(String(data: transactionData, encoding: .utf8))

        let expectedOutput =
            """
            {"mode":"BROADCAST_MODE_SYNC","tx_bytes":"CpABCo0BChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEm0KLHRlcnJhMWhzazZqcnl5cWpmaHA1ZGhjNTV0YzlqdGNreWd4MGVwMzdoZGQyEix0ZXJyYTFqbGdhcXk5bnZuMmhmNXQyc3JhOXljejhzNzd3bmY5bDBrbWdjcBoPCgR1dXNkEgcxMDAwMDAwEmcKUApGCh8vY29zbW9zLmNyeXB0by5zZWNwMjU2azEuUHViS2V5EiMKIQJXKG7D830zVXu7qgALJ3RKyQI6qZZ8rnWhgdH/kfqdxRIECgIIARgBEhMKDQoEdXVzZBIFMzAwMDAQwJoMGkAnF3n5KOt8/GP2oe0lZJKIZSmnjAy7BDpNoY35hP5wT1sWEtzVVZVgxPFfsdefJb5JnFJRcJtWL6Tne/DCN5wi"}
            """

        XCTAssertJSONEqual(transactionString, expectedOutput)
    }

    // From TrustWallet
    func testTerraV2Transaction() throws {
        let cosmosChain = CosmosChain.terraV2
        let blockchain = cosmosChain.blockchain

        let privateKey = PrivateKey(data: Data(hexString: "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data

        let publicKey: BlockchainSdk.Wallet.PublicKey = .init(seedKey: publicKeyData, derivationType: .none)
        let address = try WalletCoreAddressService(blockchain: blockchain).makeAddress(for: publicKey, with: .default)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        let txBuilder = try CosmosTransactionBuilder(publicKey: wallet.publicKey.blockchainKey, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(1)

        let transaction = Transaction(
            amount: Amount(with: cosmosChain.blockchain, value: 1),
            fee: Fee(Amount(with: cosmosChain.blockchain, value: 0.03), parameters: CosmosFeeParameters(gas: 200_000)),
            sourceAddress: wallet.address,
            destinationAddress: "terra1jlgaqy9nvn2hf5t2sra9ycz8s77wnf9l0kmgcp",
            changeAddress: wallet.address
        )

        let dataForSign = try txBuilder.buildForSign(transaction: transaction)
        XCTAssertEqual(dataForSign.hexString.lowercased(), "c5ba086438f7d37f765058c586fe3c3d8d7742682b72b1f2fe0b357f736660d3")

        let signature = try XCTUnwrap(privateKey.sign(digest: dataForSign, curve: cosmosChain.coin.curve))
        XCTAssertEqual(signature.hexString.lowercased(), "f8740b7ae3cdd8b12148b23f1dc5956031cdb2882cd01c49155e427693975bec2390c47d86b6a1895404bab28a570c09c53f89a24b85ec77d0da366a4d199f5400")

        let transactionData = try txBuilder.buildForSend(transaction: transaction, signature: signature)
        let transactionString = try XCTUnwrap(String(data: transactionData, encoding: .utf8))

        let expectedOutput =
            """
            {
                "tx_bytes": "CpEBCo4BChwvY29zbW9zLmJhbmsudjFiZXRhMS5Nc2dTZW5kEm4KLHRlcnJhMWhzazZqcnl5cWpmaHA1ZGhjNTV0YzlqdGNreWd4MGVwMzdoZGQyEix0ZXJyYTFqbGdhcXk5bnZuMmhmNXQyc3JhOXljejhzNzd3bmY5bDBrbWdjcBoQCgV1bHVuYRIHMTAwMDAwMBJoClAKRgofL2Nvc21vcy5jcnlwdG8uc2VjcDI1NmsxLlB1YktleRIjCiECVyhuw/N9M1V7u6oACyd0SskCOqmWfK51oYHR/5H6ncUSBAoCCAEYARIUCg4KBXVsdW5hEgUzMDAwMBDAmgwaQPh0C3rjzdixIUiyPx3FlWAxzbKILNAcSRVeQnaTl1vsI5DEfYa2oYlUBLqyilcMCcU/iaJLhex30No2ak0Zn1Q=",
                "mode": "BROADCAST_MODE_SYNC"
            }
            """

        XCTAssertJSONEqual(transactionString, expectedOutput)
    }
}
