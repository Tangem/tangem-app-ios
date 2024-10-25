//
//  BlockBookResponses.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 20.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct BlockBookAddressResponse: Decodable {
    let page: Int?
    let totalPages: Int?
    let itemsOnPage: Int?
    let address: String
    let balance: String
    let unconfirmedBalance: String?
    let unconfirmedTxs: Int?
    /// All transactions count
    let txs: Int
    /// Only for EVM-like. Main network transactions count
    let nonTokenTxs: Int?
    let transactions: [Transaction]?
    let tokens: [Token]?
}

extension BlockBookAddressResponse {
    struct Transaction: Decodable {
        let txid: String
        /// This field uses `snake_case` encoding, while all other fields use `camelCase` encoding,
        /// so `keyDecodingStrategy` is not an option. Again, Tron Blockbook just has a terrible API contract.
        let contractType: Int?
        /// This field uses `snake_case` encoding, while all other fields use `camelCase` encoding,
        /// so `keyDecodingStrategy` is not an option. Again, Tron Blockbook just has a terrible API contract.
        let contractName: String?
        let version: Int?
        let vin: [Vin]?
        let vout: [Vout]?
        let blockHash: String?
        let blockHeight: Int
        let confirmations: Int
        let blockTime: Int
        let value: String
        let valueIn: String?
        let fees: String
        let hex: String?
        let tokenTransfers: [TokenTransfer]?
        let ethereumSpecific: EthereumSpecific?
        let tronTXReceipt: TronTXReceipt?
        let fromAddress: String?
        let toAddress: String?
        let voteList: [String: Int]?
        
        /// - Note: Generated using `Explicit `Codable` implementation` refactor menu option.
        private enum CodingKeys: String, CodingKey {
            case txid
            case contractType = "contract_type"
            case contractName = "contract_name"
            case version
            case vin
            case vout
            case blockHash
            case blockHeight
            case confirmations
            case blockTime
            case value
            case valueIn
            case fees
            case hex
            case tokenTransfers
            case ethereumSpecific
            case tronTXReceipt
            case fromAddress
            case toAddress
            case voteList
        }
        
        /// - Note: Generated using `Explicit `Codable` implementation` refactor menu option.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.txid = try container.decode(String.self, forKey: CodingKeys.txid)
            self.contractType = try container.decodeIfPresent(Int.self, forKey: CodingKeys.contractType)
            self.contractName = try container.decodeIfPresent(String.self, forKey: CodingKeys.contractName)
            self.version = try container.decodeIfPresent(Int.self, forKey: CodingKeys.version)
            self.vin = try container.decodeIfPresent([Vin].self, forKey: CodingKeys.vin)
            self.vout = try container.decodeIfPresent([Vout].self, forKey: CodingKeys.vout)
            self.blockHash = try container.decodeIfPresent(String.self, forKey: CodingKeys.blockHash)
            self.blockHeight = try container.decode(Int.self, forKey: CodingKeys.blockHeight)
            self.confirmations = try container.decode(Int.self, forKey: CodingKeys.confirmations)
            self.blockTime = try container.decode(Int.self, forKey: CodingKeys.blockTime)
            self.value = try container.decode(String.self, forKey: CodingKeys.value)
            self.valueIn = try container.decodeIfPresent(String.self, forKey: CodingKeys.valueIn)
            self.fees = try container.decode(String.self, forKey: CodingKeys.fees)
            self.hex = try container.decodeIfPresent(String.self, forKey: CodingKeys.hex)
            self.tokenTransfers = try container.decodeIfPresent([TokenTransfer].self, forKey: CodingKeys.tokenTransfers)
            self.ethereumSpecific = try container.decodeIfPresent(EthereumSpecific.self, forKey: CodingKeys.ethereumSpecific)
            self.tronTXReceipt = try container.decodeIfPresent(TronTXReceipt.self, forKey: CodingKeys.tronTXReceipt)
            self.fromAddress = try container.decodeIfPresent(String.self, forKey: CodingKeys.fromAddress)
            self.toAddress = try container.decodeIfPresent(String.self, forKey: CodingKeys.toAddress)
            self.voteList = try container.decodeIfPresent([String: Int].self, forKey: CodingKeys.voteList)
        }
    }
    
    struct Vin: Decodable {
        let txid: String?
        let sequence: Int?
        let n: Int
        let addresses: [String]
        let isAddress: Bool
        let value: String?
        let hex: String?
        let vout: Int?
        let isOwn: Bool?
    }
    
    struct Vout: Codable {
        let value: String
        let n: Int
        let hex: String?
        let addresses: [String]
        let isAddress: Bool
        let spent: Bool?
        let isOwn: Bool?
    }
    
    /// For EVM-like blockchains
    struct TokenTransfer: Decodable {
        let type: String?
        let from: String
        let to: String
        /// - Warning: For some blockchains (e.g. Ethereum POW) the contract address is stored
        /// in the `token` field instead of the `contract` field of the response.
        let contract: String?
        let token: String?
        let name: String?
        let symbol: String?
        let decimals: Int
        let value: String?
    }

    enum StatusType: Int, Decodable {
        case pending = -1
        case failure = 0
        case ok = 1
    }

    /// For EVM-like blockchains
    struct EthereumSpecific: Decodable {
        let status: StatusType?
        let nonce: Int?
        let gasLimit: Decimal?
        let gasUsed: Decimal?
        let gasPrice: String?
        let data: String?
        let parsedData : ParsedData?

        struct ParsedData: Decodable {
            /// First 4byte from data. E.g. `0x617ba037`
            let methodId: String
            let name: String
        }
    }

    /// Tron blockchain specific info.
    /// There are many more fields in this response, but we map only the required ones.
    struct TronTXReceipt: Decodable {
        let status: StatusType?
    }
    
    struct Token: Decodable {
        let type: String?
        let id: String?
        let name: String?
        let contract: String?
        let transfers: Int?
        let symbol: String?
        let decimals: Int?
        let balance: String?
    }
}

struct BlockBookUnspentTxResponse: Decodable {
    let txid: String
    let vout: Int
    let value: String
    let confirmations: Int
    let lockTime: Int?
    let height: Int?
    let coinbase: Bool?
    let scriptPubKey: String?
}

struct BlockBookFeeResponse: Decodable {
    struct Result: Decodable {
        let feerate: Double
    }
    
    let result: Result
}


struct SendResponse: Decodable {
    let result: String
}

struct NodeEstimateFeeResponse: Decodable {
    let result: Decimal
    let id: String
}
