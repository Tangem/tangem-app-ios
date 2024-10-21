//
//  PolygonZkEvmExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PolygonZkEvmExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://faucet.quicknode.com/polygon/zkevm-goerli/")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://cardona-zkevm.polygonscan.com"
        } else {
            "https://zkevm.polygonscan.com"
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
