//
//  ApeChainExternalLinkProvider.swift
//  TangemApp
//
//  Created by Aleksei Lobankov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct ApeChainExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String

    let testnetFaucetURL = URL(string: "https://curtis.hub.caldera.xyz")

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://curtis.explorer.caldera.xyz"
            : "https://apechain.calderaexplorer.xyz"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
