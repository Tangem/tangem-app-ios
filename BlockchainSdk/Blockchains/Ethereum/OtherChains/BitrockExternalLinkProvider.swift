//
//  BitrockExternalLinkProvider.swift
//  TangemApp
//
//  Created by Aleksei Lobankov on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct BitrockExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String

    let testnetFaucetURL = URL(string: "https://faucet.bit-rock.io")

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://testnetscan.bit-rock.io"
            : "https://explorer.bit-rock.io"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
