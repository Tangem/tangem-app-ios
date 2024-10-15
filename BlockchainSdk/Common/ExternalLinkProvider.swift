//
//  BlockchainExplorerProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 04.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExternalLinkProvider {
    var testnetFaucetURL: URL? { get }

    func url(address: String, contractAddress: String?) -> URL?
    func url(transaction hash: String) -> URL?
}
