//
//  SolanaEd25519Tests.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 19/10/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import XCTest
import Combine
@testable import BlockchainSdk
@testable import Solana_Swift

private let raisedError = SolanaError.nullValue

final class SolanaEd25519Tests: XCTestCase {
    private class CoinSigner: TransactionSigner {
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

    private class TokenSigner: TransactionSigner {
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

    private var networkingRouter: NetworkingRouter!
    private var solanaSdk: Solana!
    private var manager: SolanaWalletManager!

    private var bag = Set<AnyCancellable>()

    private let network: RPCEndpoint = .devnetSolana
    private let walletPubKey = Data(hex: "B148CC30B144E8F214AE5754C753C40A9BF2A3359DB4246E03C6A2F61A82C282")
    private let address = "Cw3YcfqzRSa7xT7ecpR5E4FKDQU6aaxz5cWje366CZbf"
    private let blockchain = Blockchain.solana(curve: .ed25519, testnet: true)
    private let feeParameters = SolanaFeeParameters(computeUnitLimit: nil, computeUnitPrice: nil, accountCreationFee: 0)

    private let coinSigner = CoinSigner()
    private let tokenSigner = TokenSigner()

    override func setUp() {
        super.setUp()
        networkingRouter = .init(endpoints: [.testnetSolana], apiLogger: nil)
        solanaSdk = .init(router: networkingRouter, accountStorage: SolanaDummyAccountStorage())
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addrs = try! service.makeAddress(from: walletPubKey)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: addrs])

        manager = .init(wallet: wallet)
        manager.solanaSdk = solanaSdk
        manager.usePriorityFees = false
        manager.networkService = SolanaNetworkService(solanaSdk: solanaSdk, blockchain: blockchain, hostProvider: networkingRouter)
    }

    func testCoinTransactionSize() {
        let transaction = Transaction(
            amount: .zeroCoin(for: blockchain),
            fee: Fee(.zeroCoin(for: blockchain), parameters: feeParameters),
            sourceAddress: manager.wallet.address,
            destinationAddress: "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ",
            changeAddress: manager.wallet.address,
            contractAddress: nil
        )

        let expected = expectation(description: "Waiting for response")

        processResult(manager.send(transaction, signer: coinSigner), expectationToFill: expected)
        waitForExpectations(timeout: 10)
    }

    func testTokenTransactionSize() {
        let type: Amount.AmountType = .token(
            value: .init(
                name: "My Token",
                symbol: "MTK",
                contractAddress: "BHZxQcNpty7W8EVT2kxWREZ9QxNDigXrjRb7SWTAt9YK",
                decimalCount: 9
            )
        )
        let transaction = Transaction(
            amount: Amount(with: blockchain, type: type, value: 0),
            fee: Fee(Amount(with: blockchain, type: type, value: 0), parameters: feeParameters),
            sourceAddress: manager.wallet.address,
            destinationAddress: "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ",
            changeAddress: manager.wallet.address
        )
        let expected = expectation(description: "Waiting for response")

        processResult(manager.send(transaction, signer: tokenSigner), expectationToFill: expected)
        waitForExpectations(timeout: 10)
    }

    private func processResult(_ publisher: AnyPublisher<TransactionSendResult, SendTxError>, expectationToFill: XCTestExpectation) {
        bag.insert(
            publisher.sink(receiveCompletion: { completion in
                defer {
                    expectationToFill.fulfill()
                }

                guard case .failure(let error) = completion else {
                    XCTFail("Wrong complition received")
                    return
                }

                guard let castedError = error.error as? SolanaError else {
                    XCTFail("Wrong error returned from manager")
                    return
                }

                XCTAssertEqual(castedError.localizedDescription, raisedError.localizedDescription)
            }, receiveValue: { _ in
                XCTFail("Test shouldn't receive value")
            })
        )
    }
}

extension SolanaError: Equatable {
    public static func == (lhs: Solana_Swift.SolanaError, rhs: Solana_Swift.SolanaError) -> Bool {
        switch (lhs, rhs) {
        case (.other(let message1), .other(let message2)):
            return message1 == message2
        default:
            return false
        }
    }
}
