//
//  WalletModel+.swift
//  Tangem
//
//  Created by Andrew Son on 04/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

typealias WalletModelId = WalletModel.ID

extension WalletModel: Equatable {
    static func == (lhs: WalletModel, rhs: WalletModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension WalletModel {
    struct Id: Hashable, Identifiable, Equatable {
        let id: String
        let tokenItem: TokenItem

        init(tokenItem: TokenItem) {
            self.tokenItem = tokenItem

            let network = tokenItem.networkId
            let contract = tokenItem.contractAddress ?? "coin"
            let path = tokenItem.blockchainNetwork.derivationPath?.rawPath ?? "no_derivation"
            id = "\(network)_\(contract)_\(path)"
        }
    }
}

extension WalletModel: Identifiable {
    var id: String {
        walletModelId.id
    }
}

extension WalletModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(walletModelId)
    }
}

extension WalletModel {
    enum TransactionHistoryState: CustomStringConvertible {
        case notSupported
        case notLoaded
        case loading
        case loaded(items: [TransactionRecord])
        case error(Error)

        var description: String {
            switch self {
            case .notSupported:
                return "TransactionHistoryState.notSupported"
            case .notLoaded:
                return "TransactionHistoryState.notLoaded"
            case .loading:
                return "TransactionHistoryState.loading"
            case .loaded(let items):
                return "TransactionHistoryState.loaded with items: \(items.count)"
            case .error(let error):
                return "TransactionHistoryState.error with \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension WalletModel: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(
            self,
            userInfo: [
                "name": name,
                "isMainToken": isMainToken,
                "tokenItem": "\(tokenItem.name) (\(tokenItem.networkName))",
            ]
        )
    }
}
