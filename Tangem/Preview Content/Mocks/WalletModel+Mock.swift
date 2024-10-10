//
//  WalletModel+Mock.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal
import Combine

extension WalletModel {
    static let mockETH = WalletModel(
        walletManager: EthereumWalletManagerMock(),
        stakingManager: StakingManagerMock(),
        transactionHistoryService: nil,
        amountType: .coin,
        shouldPerformHealthCheck: false,
        isCustom: false
    )
}

class EthereumWalletManagerMock: WalletManager {
    var cardTokens: [BlockchainSdkLocal.Token] { [] }

    func update() {}

    func updatePublisher() -> AnyPublisher<BlockchainSdkLocal.WalletManagerState, Never> {
        Empty().eraseToAnyPublisher()
    }

    func setNeedsUpdate() {}

    func removeToken(_ token: BlockchainSdkLocal.Token) {}

    func addToken(_ token: BlockchainSdkLocal.Token) {}

    func addTokens(_ tokens: [BlockchainSdkLocal.Token]) {}

    var wallet: BlockchainSdkLocal.Wallet = .init(
        blockchain: .ethereum(testnet: false),
        addresses: [.default: PlainAddress(
            value: "0xtestaddress",
            publicKey: Wallet.PublicKey(seedKey: Data(), derivationType: .none),
            type: .default
        )]
    )
    var walletPublisher: AnyPublisher<BlockchainSdkLocal.Wallet, Never> { .just(output: wallet) }
    var statePublisher: AnyPublisher<BlockchainSdkLocal.WalletManagerState, Never> { .just(output: .initial) }
    var currentHost: String { "" }
    var outputsCount: Int? { nil }

    func send(_ transaction: BlockchainSdkLocal.Transaction, signer: BlockchainSdkLocal.TransactionSigner) -> AnyPublisher<BlockchainSdkLocal.TransactionSendResult, SendTxError> {
        Empty().eraseToAnyPublisher()
    }

    func validate(fee: BlockchainSdkLocal.Fee) throws {}
    func validate(amount: BlockchainSdkLocal.Amount) throws {}
    var allowsFeeSelection: Bool { true }

    func getFee(amount: BlockchainSdkLocal.Amount, destination: String) -> AnyPublisher<[BlockchainSdkLocal.Fee], Error> {
        .just(output: [])
    }
}
