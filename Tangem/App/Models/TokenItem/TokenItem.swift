//
//  TokenItem.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct TangemSdk.DerivationPath

typealias TokenItemId = String

enum TokenItem: Hashable, Codable {
    case blockchain(BlockchainNetwork)
    case token(Token, BlockchainNetwork)

    var isBlockchain: Bool { token == nil }

    var isToken: Bool { token != nil }

    var id: TokenItemId? {
        switch self {
        case .token(let token, _):
            return token.id
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork.blockchain.coinId
        }
    }

    var currencyId: String? {
        switch self {
        case .token(let token, _):
            return token.id
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork.blockchain.currencyId
        }
    }

    var networkId: String {
        return blockchain.networkId
    }

    var blockchain: Blockchain {
        switch self {
        case .token(_, let blockchainNetwork):
            return blockchainNetwork.blockchain
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork.blockchain
        }
    }

    var blockchainNetwork: BlockchainNetwork {
        switch self {
        case .token(_, let blockchainNetwork):
            return blockchainNetwork
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork
        }
    }

    var amountType: Amount.AmountType {
        switch self {
        case .token(let token, _):
            return .token(value: token)
        case .blockchain:
            return .coin
        }
    }

    var currencySymbol: String {
        switch self {
        case .token(let token, _):
            return token.symbol
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork.blockchain.currencySymbol
        }
    }

    var token: Token? {
        switch self {
        case .token(let token, _):
            return token
        default:
            return nil
        }
    }

    var name: String {
        switch self {
        case .token(let token, _):
            return token.name
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork.blockchain.coinDisplayName
        }
    }

    var contractName: String? {
        switch self {
        case .token:
            return blockchain.tokenTypeName
        case .blockchain:
            if SupportedBlockchains.l2Blockchains.contains(where: { $0.networkId == networkId }) {
                return "MAIN L2"
            }

            return "MAIN"
        }
    }

    var contractAddress: String? {
        token?.contractAddress
    }

    var networkName: String {
        blockchain.displayName
    }

    var decimalCount: Int {
        switch self {
        case .token(let token, _):
            return token.decimalCount
        case .blockchain(let blockchainNetwork):
            return blockchainNetwork.blockchain.decimalCount
        }
    }

    var decimalValue: Decimal {
        pow(10, decimalCount)
    }

    // We can't sign hashes on firmware prior 4.52
    var hasLongHashes: Bool {
        switch blockchain {
        case .solana:
            return isToken ? true : false
        default:
            return false
        }
    }

    // We can't sign hashes on firmware prior 4.52
    var hasLongHashesForStaking: Bool {
        switch blockchain {
        case .solana:
            return true
        default:
            return false
        }
    }
}
