//
// SuiExternalLinkPrivider.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 06.09.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SuiExternalLinkProvider {
    private let isTestnet: Bool
    
    private var baseExplorerUrl: String {
        if isTestnet {
            "https://suiscan.xyz/testnet"
        } else {
            "https://suiscan.xyz/mainnet"
        }
    }
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension SuiExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://discord.com/channels/916379725201563759")
    }
    
    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/account/\(address)")
    }
}
