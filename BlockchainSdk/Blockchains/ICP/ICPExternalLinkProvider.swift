//
//  ICPExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 12.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ICPExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return nil
    }
    
    private let baseExplorerURL = URL(string: "https://dashboard.internetcomputer.org")

    func url(address: String, contractAddress: String?) -> URL? {
        baseExplorerURL?.appendingPathComponent("account").appendingPathComponent(address)
    }

    func url(transaction hash: String) -> URL? {
        baseExplorerURL?.appendingPathComponent("transaction").appendingPathComponent(hash)
    }
}
