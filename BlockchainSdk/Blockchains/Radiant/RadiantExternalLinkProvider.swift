//
//  RadiantExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantExternalLinkProvider {}

extension RadiantExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    private var baseExplorerHost: String {
        return "https://radiantexplorer.com"
    }
    
    /*
     example: https://radiantexplorer.com/tx/43b45084fe21a2c53484ee9cdd860d1514daec28fd191652886f2006e0b110f2
     */
    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerHost)/tx/\(hash)")
    }
    
    /*
     example: https://radiantexplorer.com/address/1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf
     */
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerHost)/address/\(address)")
    }
}
