//
//  OctaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OctaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://app.telos.net/testnet/developers")
    }
    
    func url(transaction hash: String) -> URL? {
        return URL(string: "https://explorer.octa.space/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://explorer.octa.space/address/\(address)")
    }
}
