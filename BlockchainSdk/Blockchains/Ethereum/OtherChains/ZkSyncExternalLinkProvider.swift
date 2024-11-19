//
//  ZkSyncExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ZkSyncExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://learnweb3.io/faucets/zksync_sepolia/")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://sepolia.explorer.zksync.io"
        } else {
            "https://explorer.zksync.io"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
