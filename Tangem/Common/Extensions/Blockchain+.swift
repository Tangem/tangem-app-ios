//
//  Blockchain+.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Blockchain {
    /// Should be used to get the actual currency rate
    var currencyId: String {
        switch self {
        case .arbitrum(let testnet),
             .optimism(let testnet),
             .aurora(let testnet),
             .manta(let testnet),
             .zkSync(let testnet),
             .polygonZkEVM(let testnet),
             .base(let testnet):
            return Blockchain.ethereum(testnet: testnet).coinId
        default:
            return coinId
        }
    }

    /// Should be used to get a icon from the`Tokens.xcassets` file
    var iconName: String {
        var name = "\(self)".lowercased()

        if let index = name.firstIndex(of: "(") {
            name = String(name.prefix(upTo: index))
        }

        if name == "binance" {
            return "bsc"
        }

        return name
    }

    /// Should be used to get a filled icon from the`Tokens.xcassets` file
    var iconNameFilled: String { "\(iconName).fill" }
}

// MARK: - Blockchain ID

extension Set<Blockchain> {
    subscript(networkId: String) -> Blockchain? {
        // The "test" suffix no longer needed
        // since the coins are selected from the supported blockchains list
        // But we should remove it to support old application versions
        let testnetId = "/test"

        let clearNetworkId = networkId.replacingOccurrences(of: testnetId, with: "")
        if let blockchain = first(where: { $0.networkId == clearNetworkId }) {
            return blockchain
        }

        AppLog.shared.debug("⚠️⚠️⚠️ Blockchain with id: \(networkId) isn't contained in supported blockchains")
        return nil
    }
}

extension Blockchain {
    /// Provides a more descriptive display name for the fee currency (ETH) for some Ethereum L2s,
    /// for example: `'Optimistic Ethereum (ETH)'` instead of just `'ETH'`
    var feeDisplayName: String {
        switch self {
        case .arbitrum,
             .optimism,
             .aurora,
             .manta,
             .zkSync,
             .polygonZkEVM,
             .base:
            return displayName + " (\(currencySymbol))"
        default:
            return currencySymbol
        }
    }
}
