//
//  ExpressPendingTransactionRecord.swift
//  Tangem
//
//  Created by Andrew Son on 28/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk
import TangemFoundation

struct ExpressPendingTransactionRecord: Codable, Equatable {
    let userWalletId: String
    let expressTransactionId: String
    let destinationTokenTxInfo: TokenTxInfo
    let provider: Provider
    let externalTxId: String?
    let externalTxURL: String?
    let date: Date

    let expressSpecific: ExpressSpecific?
    let onrampSpecific: OnrampSpecific?

    // Flag for hide transaction from UI. But keep saving in the storage
    var isHidden: Bool
    var transactionStatus: PendingExpressTransactionStatus

    var refundedTokenItem: TokenItem?
}

extension ExpressPendingTransactionRecord {
    struct ExpressSpecific: Codable, Equatable {
        let transactionType: TransactionType
        let transactionHash: String
        let sourceTokenTxInfo: TokenTxInfo
        let feeString: String

        var fee: Decimal {
            convertToDecimal(feeString)
        }

        init(
            transactionType: ExpressPendingTransactionRecord.TransactionType,
            transactionHash: String,
            sourceTokenTxInfo: ExpressPendingTransactionRecord.TokenTxInfo,
            feeString: String
        ) {
            self.transactionType = transactionType
            self.transactionHash = transactionHash
            self.sourceTokenTxInfo = sourceTokenTxInfo
            self.feeString = feeString
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            transactionType = try container.decode(ExpressPendingTransactionRecord.TransactionType.self, forKey: .transactionType)
            transactionHash = try container.decode(String.self, forKey: .transactionHash)

            if let sourceTokenTxInfo = try? container.decode(ExpressPendingTransactionRecord.TokenTxInfo.self, forKey: .sourceTokenTxInfo) {
                self.sourceTokenTxInfo = sourceTokenTxInfo
            } else {
                let legacySourceTokenTxInfo = try container.decode(ExpressPendingTransactionRecord.LegacyTokenTxInfo.self, forKey: .sourceTokenTxInfo)
                sourceTokenTxInfo = try legacySourceTokenTxInfo.mapToTokenTxInfo()
            }

            feeString = try container.decode(String.self, forKey: .feeString)
        }
    }

    struct OnrampSpecific: Codable, Equatable {
        let fromAmount: Decimal
        let fromCurrencyCode: String
    }

    struct TokenTxInfo: Codable, Equatable {
        let tokenItem: TokenItem
        let amountString: String
        let isCustom: Bool

        var amount: Decimal {
            convertToDecimal(amountString)
        }
    }

    enum TransactionType: String, Codable, Equatable {
        case send
        case swap

        static func type(from expressType: ExpressTransactionType) -> TransactionType {
            switch expressType {
            case .send: return .send
            case .swap: return .swap
            }
        }
    }

    struct Provider: Codable, Equatable {
        let id: String
        let name: String
        let iconURL: URL?
        let type: ProviderType

        init(id: String, name: String, iconURL: URL?, type: ProviderType) {
            self.id = id
            self.name = name
            self.iconURL = iconURL
            self.type = type
        }

        init(provider: ExpressProvider) {
            id = provider.id
            name = provider.name
            iconURL = provider.imageURL
            type = .type(from: provider.type)
        }
    }

    enum ProviderType: String, Codable, Equatable {
        case cex
        case dex
        case dexBridge
        case unknown
        case onramp

        static func type(from type: ExpressProviderType) -> ProviderType {
            switch type {
            case .dex: return .dex
            case .cex: return .cex
            case .dexBridge: return .dexBridge
            case .onramp: return .onramp
            case .unknown: return .unknown
            }
        }

        var supportStatusTracking: Bool {
            switch self {
            case .cex, .dexBridge, .onramp:
                return true
            case .dex, .unknown:
                return false
            }
        }
    }
}

private func convertToDecimal(_ str: String) -> Decimal {
    let decimalSeparator = Locale.posixEnUS.decimalSeparator ?? "."
    let cleanedStr = str.replacingOccurrences(of: ",", with: decimalSeparator)
    return Decimal(stringValue: cleanedStr) ?? 0
}

// MARK: - Migration

extension ExpressPendingTransactionRecord {
    private enum MigrationError: Error {
        case networkMismatch
    }

    private struct LegacyTokenTxInfo: Decodable {
        let tokenItem: LegacyTokenItem
        let amountString: String
        let isCustom: Bool
        let blockchainNetwork: BlockchainNetwork

        func mapToTokenTxInfo() throws -> TokenTxInfo {
            return .init(
                tokenItem: try tokenItem.mapToTokenItem(blockchainNetwork: blockchainNetwork),
                amountString: amountString,
                isCustom: isCustom
            )
        }
    }

    private enum LegacyTokenItem: Decodable {
        case blockchain(Blockchain)
        case token(Token, Blockchain)

        private var blockchain: Blockchain {
            switch self {
            case .token(_, let blockchain):
                return blockchain
            case .blockchain(let blockchain):
                return blockchain
            }
        }

        func mapToTokenItem(blockchainNetwork: BlockchainNetwork) throws -> TokenItem {
            guard blockchain == blockchainNetwork.blockchain else {
                throw MigrationError.networkMismatch
            }

            switch self {
            case .token(let token, _):
                return .token(token, blockchainNetwork)
            case .blockchain:
                return .blockchain(blockchainNetwork)
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userWalletId = try container.decode(String.self, forKey: .userWalletId)
        expressTransactionId = try container.decode(String.self, forKey: .expressTransactionId)

        if let destinationTokenTxInfo = try? container.decode(ExpressPendingTransactionRecord.TokenTxInfo.self, forKey: .destinationTokenTxInfo) {
            self.destinationTokenTxInfo = destinationTokenTxInfo
        } else {
            let legacyDestinationTokenTxInfo = try container.decode(ExpressPendingTransactionRecord.LegacyTokenTxInfo.self, forKey: .destinationTokenTxInfo)
            destinationTokenTxInfo = try legacyDestinationTokenTxInfo.mapToTokenTxInfo()
        }

        provider = try container.decode(ExpressPendingTransactionRecord.Provider.self, forKey: .provider)
        externalTxId = try container.decodeIfPresent(String.self, forKey: .externalTxId)
        externalTxURL = try container.decodeIfPresent(String.self, forKey: .externalTxURL)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        transactionStatus = try container.decode(PendingExpressTransactionStatus.self, forKey: .transactionStatus)
        date = try container.decode(Date.self, forKey: .date)

        expressSpecific = try container.decodeIfPresent(ExpressSpecific.self, forKey: .expressSpecific)
        onrampSpecific = try container.decodeIfPresent(OnrampSpecific.self, forKey: .onrampSpecific)
    }
}
