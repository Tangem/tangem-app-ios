//
//  TransactionRecord.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionRecord: Hashable {
    public let hash: String
    /// Index of an individual transaction within the parent transaction (if applicable).
    /// For example, a single EVM transaction may consist of multiple token transactions (with indices 0, 1, 2 and so on)
    public let index: Int
    public let source: SourceType
    public let destination: DestinationType
    public let fee: Fee
    public let status: TransactionStatus
    public let isOutgoing: Bool
    public let type: TransactionType
    public let date: Date?
    public let tokenTransfers: [TokenTransfer]?
    
    public init(
        hash: String,
        index: Int,
        source: SourceType,
        destination: DestinationType,
        fee: Fee,
        status: TransactionStatus,
        isOutgoing: Bool,
        type: TransactionType,
        date: Date?,
        tokenTransfers: [TokenTransfer]? = nil
    ) {
        self.index = index
        self.hash = hash
        self.source = source
        self.destination = destination
        self.fee = fee
        self.status = status
        self.isOutgoing = isOutgoing
        self.type = type
        self.date = date
        self.tokenTransfers = tokenTransfers
    }
}

// MARK: - TransactionType

public extension TransactionRecord {
    enum TransactionType: Hashable {
        case transfer
        /// Contains contract method id (like `0x357a150b`).
        case contractMethodIdentifier(id: String)
        /// Contains human-readable contract method name (like `swap`).
        case contractMethodName(name: String)
        case staking(type: StakingTransactionType, validator: String?)
        
        public enum StakingTransactionType {
            case stake
            case unstake
            case vote
            case withdraw
            case claimRewards
        }
    }
}

// MARK: - TransactionStatus

public extension TransactionRecord {
    enum TransactionStatus: Hashable {
        case unconfirmed
        case failed
        case confirmed
    }
}

// MARK: - Source

public extension TransactionRecord {
    enum SourceType: Hashable {
        case single(Source)
        case multiple([Source])
    }
    
    struct Source: Hashable {
        public let address: String
        public let amount: Decimal
        
        public init(address: String, amount: Decimal) {
            self.address = address
            self.amount = amount
        }
    }
}

// MARK: - Destination

public extension TransactionRecord {
    enum DestinationType: Hashable {
        case single(Destination)
        case multiple([Destination])
    }
    
    struct Destination: Hashable {
        public let address: Address
        public let amount: Decimal
        
        public init(address: TransactionRecord.Destination.Address, amount: Decimal) {
            self.address = address
            self.amount = amount
        }
        
        public enum Address: Hashable {
            case user(String)
            /// Contact address for token-supported blockchains
            case contract(String)
            
            public var string: String {
                switch self {
                case .user(let address):
                    return address
                case .contract(let address):
                    return address
                }
            }
        }
    }
}

// MARK: - TokenTransfer

public extension TransactionRecord {
    struct TokenTransfer: Hashable {
        public let source: String
        public let destination: String
        public let amount: Decimal
        public let name: String?
        public let symbol: String?
        public let decimals: Int?
        public let contract: String?
    }
}
