//
//  SolanaEd25519Slip0010Tests.swift
//  BlockchainSdkTests
//
//  Created by Sergey Balashov on 25.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Combine
@testable import BlockchainSdk
@testable import SolanaSwift

final class SolanaEd25519Slip0010Tests: XCTestCase {
    private var manager: SolanaWalletManager!

    private let walletPubKey = Data(hex: "B148CC30B144E8F214AE5754C753C40A9BF2A3359DB4246E03C6A2F61A82C282")
    private let address = "Cw3YcfqzRSa7xT7ecpR5E4FKDQU6aaxz5cWje366CZbf"
    private let blockchain = Blockchain.solana(curve: .ed25519, testnet: false)
    private let feeParameters = SolanaFeeParameters(computeUnitLimit: nil, computeUnitPrice: nil, accountCreationFee: 0)

    private let coinSigner = SolanaSignerTestUtility.CoinSigner()
    private let tokenSigner = SolanaSignerTestUtility.TokenSigner()

    override func setUp() {
        super.setUp()
        let solanaSdk = Solana(router: SolanaDummyNetworkRouter(), accountStorage: SolanaDummyAccountStorage())
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let address = try! service.makeAddress(from: walletPubKey)
        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        manager = .init(wallet: wallet)
        manager.solanaSdk = solanaSdk
        manager.usePriorityFees = false
        manager.networkService = SolanaNetworkService(
            solanaSdk: solanaSdk,
            blockchain: blockchain,
            hostProvider: networkingRouter
        )
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

        try await manager.send(transaction, signer: coinSigner).async()
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

        try await manager.send(transaction, signer: coinSigner).async()
    }
}
