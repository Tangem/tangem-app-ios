//
//  SonicExternalLinkProvider.swift
//  TangemApp
//
//  Created by Aleksei Lobankov on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SonicExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String

    let testnetFaucetURL = URL(string: "https://testnet.soniclabs.com/account")

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://testnet.sonicscan.org"
            : "https://sonicscan.org"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
