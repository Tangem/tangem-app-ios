//
//  SolanaSignerTestUtility.swift
//  BlockchainSdkTests
//
//  Created by Alexander Skibin on 13.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
import Combine
@testable import BlockchainSdk
@testable import SolanaSwift

private let raisedError = SolanaError.nullValue

enum SolanaSignerTestUtility {
    class CoinSigner: TransactionSigner {
        private let sizeTester = TransactionSizeTesterUtility()

        func sign(hashes: [Data], walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
            sizeTester.testTxSizes(hashes)
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }

        func sign(hash: Data, walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<Data, Error> {
            sizeTester.testTxSize(hash)
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }
    }

    class TokenSigner: TransactionSigner {
        private let sizeTester = TransactionSizeTesterUtility()

        func sign(hashes: [Data], walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
            hashes.forEach {
                _ = sign(hash: $0, walletPublicKey: walletPublicKey)
            }
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }

        func sign(hash: Data, walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<Data, Error> {
            XCTAssertTrue(sizeTester.isValidForCos4_52AndAbove(hash))
            XCTAssertFalse(sizeTester.isValidForCosBelow4_52(hash))
            XCTAssertFalse(sizeTester.isValidForiPhone7(hash))
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }
    }
}
