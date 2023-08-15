//
//  StorageEntry.V1.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token
import enum BlockchainSdk.Blockchain
import enum BlockchainSdk.BlockchainSdkError

extension StorageEntry {
    enum V1 {
        enum Entry: Codable {
            case blockchain(Blockchain)
            case token(Token)

            var blockchain: Blockchain {
                switch self {
                case .blockchain(let blockchain):
                    return blockchain
                case .token(let token):
                    return token.blockchain
                }
            }

            var token: Token? {
                switch self {
                case .blockchain:
                    return nil
                case .token(let token):
                    return token
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                if let token = try? container.decode(Token.self) {
                    self = .token(token)
                    return
                }

                if let blockchain = try? container.decode(Blockchain.self) {
                    self = .blockchain(blockchain)
                    return
                }

                if let tokenDto = try? container.decode(CloudToken.self) {
                    let token = Token(
                        name: tokenDto.name,
                        symbol: tokenDto.symbol,
                        contractAddress: tokenDto.contractAddress,
                        decimalCount: tokenDto.decimalCount,
                        customIconUrl: tokenDto.customIconUrl,
                        blockchain: .ethereum(testnet: false)
                    )
                    self = .token(token)
                    return
                }

                throw BlockchainSdkError.decodingFailed
            }
        }

        struct Token: Codable {
            let name: String
            let symbol: String
            let contractAddress: String
            let decimalCount: Int
            let customIconUrl: String?
            let blockchain: Blockchain

            var newToken: BlockchainSdk.Token {
                .init(
                    name: name,
                    symbol: symbol,
                    contractAddress: contractAddress,
                    decimalCount: decimalCount,
                    customIconUrl: customIconUrl
                )
            }
        }

        struct CloudToken: Decodable {
            let name: String
            let symbol: String
            let contractAddress: String
            let decimalCount: Int
            let customIcon: String?
            let customIconUrl: String?
        }
    }
}
