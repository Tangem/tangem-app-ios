//
//  PolygonTransactionHistoryResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PolygonTransactionHistoryResult {
    enum Result {
        case description(_ description: String)
        case transactions(_ transactions: [Transaction])
    }

    /// - Note: There are many more fields in this response, but we map only the required ones.
    struct Transaction {
        let confirmations: String
        let contractAddress: String?
        let from: String
        let functionName: String?
        let gasPrice: String
        let gasUsed: String
        let hash: String
        let isError: String?
        let timeStamp: String
        let to: String
        /// This field uses `snake_case` encoding, while all other fields use `camelCase` encoding,
        /// so `keyDecodingStrategy` is not an option and we must use custom coding keys.
        let txReceiptStatus: String?
        let value: String
    }

    let status: String
    let message: String?
    let result: Result
}

// MARK: - Decodable protocol conformance

extension PolygonTransactionHistoryResult: Decodable {
    enum CodingKeys: CodingKey {
        case status
        case message
        case result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.status = try container.decode(String.self, forKey: .status)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)

        if let description = try? container.decodeIfPresent(String.self, forKey: .result) {
            self.result = .description(description)
        } else {
            let transactions = try container.decode([Transaction].self, forKey: .result)
            self.result = .transactions(transactions)
        }
    }
}

extension PolygonTransactionHistoryResult.Transaction: Decodable {
    private enum CodingKeys: String, CodingKey {
        case confirmations
        case contractAddress
        case from
        case functionName
        case gasPrice
        case gasUsed
        case hash
        case isError
        case timeStamp
        case to
        case txReceiptStatus = "txreceipt_status"
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.confirmations = try container.decode(String.self, forKey: CodingKeys.confirmations)
        self.contractAddress = try container.decodeIfPresent(String.self, forKey: CodingKeys.contractAddress)
        self.from = try container.decode(String.self, forKey: CodingKeys.from)
        self.functionName = try container.decodeIfPresent(String.self, forKey: CodingKeys.functionName)
        self.gasPrice = try container.decode(String.self, forKey: CodingKeys.gasPrice)
        self.gasUsed = try container.decode(String.self, forKey: CodingKeys.gasUsed)
        self.hash = try container.decode(String.self, forKey: CodingKeys.hash)
        self.isError = try container.decodeIfPresent(String.self, forKey: CodingKeys.isError)
        self.timeStamp = try container.decode(String.self, forKey: CodingKeys.timeStamp)
        self.to = try container.decode(String.self, forKey: CodingKeys.to)
        self.txReceiptStatus = try container.decodeIfPresent(String.self, forKey: CodingKeys.txReceiptStatus)
        self.value = try container.decode(String.self, forKey: CodingKeys.value)
    }
}
