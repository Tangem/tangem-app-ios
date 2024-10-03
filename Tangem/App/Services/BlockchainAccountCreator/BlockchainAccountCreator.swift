//
//  BlockchainAccountCreator.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

struct BlockchainAccountCreator {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    /// Sometimes `blockchain.networkId` differs from the `networkId` required by the `createAccount` API endpoint.
    private func networkId(for blockchain: Blockchain) -> String {
        switch blockchain {
        case .hedera:
            return "hedera"
        default:
            assertionFailure("Make sure that `blockchain.networkId` is suitable for your needs")
            return blockchain.networkId
        }
    }
}

// MARK: - AccountCreator protocol conformance

extension BlockchainAccountCreator: AccountCreator {
    func createAccount(blockchain: Blockchain, publicKey: Wallet.PublicKey) -> any Publisher<CreatedAccount, Error> {
        return tangemApiService
            .createAccount(networkId: networkId(for: blockchain), publicKey: publicKey.blockchainKey.hexString)
            .tryMap { HederaCreatedAccount(accountId: $0.data.accountId) }
    }
}
