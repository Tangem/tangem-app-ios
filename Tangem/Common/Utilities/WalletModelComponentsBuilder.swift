//
//  WalletModelComponentsBuilder.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.Amount

// TODO: Andrey Fedorov - Remove after migration to actual types from the domain layer (IOS-4152)
struct WalletModelComponentsBuilder {
    private let supportedBlockchains: Set<Blockchain>

    init(
        supportedBlockchains: Set<Blockchain>
    ) {
        self.supportedBlockchains = supportedBlockchains
    }

    func buildBlockchainNetwork(from token: UserTokenList.Token) -> BlockchainNetwork? {
        guard let blockchain = supportedBlockchains[token.networkId] else { return nil }

        return BlockchainNetwork(blockchain, derivationPath: token.derivationPath)
    }

    func buildWalletModelID(from token: UserTokenList.Token) -> WalletModel.ID? {
        guard let blockchainNetwork = buildBlockchainNetwork(from: token) else { return nil }

        let amountType = amountType(from: token)

        return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: amountType).id
    }

    private func amountType(from token: UserTokenList.Token) -> Amount.AmountType {
        if let contractAddress = token.contractAddress {
            return .token(
                value: .init(
                    name: token.name,
                    symbol: token.symbol,
                    contractAddress: contractAddress,
                    decimalCount: token.decimals,
                    id: token.id
                )
            )
        } else {
            return .coin
        }
    }
}
