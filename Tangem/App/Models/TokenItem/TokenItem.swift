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

enum TokenItem: Hashable, Codable {
    case blockchain(BlockchainNetwork)
    case token(Token, BlockchainNetwork)

    var isBlockchain: Bool { token == nil }

    var isToken: Bool { token != nil }

    var id: String? {
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
            return blockchainNetwork.blockchain.displayName
        }
    }

    var contractName: String? {
        switch self {
        case .token:
            return blockchain.tokenTypeName
        case .blockchain:
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

    // We can't sign transactions at legacy devices for this blockchains
    var hasLongTransactions: Bool {
        switch blockchain {
        case .solana:
            return isToken ? true : false
        case .chia:
            return true
        default:
            return false
        }
    }
}
