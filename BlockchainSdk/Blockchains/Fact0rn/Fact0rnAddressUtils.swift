//
//  Fact0rnAddressUtils.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 31.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Fact0rnAddressUtils {
    /*
     Specify electrum api network

     The hash function the server uses for script hashing. The client must use this function to hash pay-to-scripts to produce script hashes to send to the server. The default is “sha256”. “sha256” is currently the only acceptable value.

     More: https://electrumx.readthedocs.io/en/latest/protocol-basics.html#script-hashes
     */
    func prepareScriptHash(address: String) throws -> String {
        

        return Data(scriptHashData.sha256().reversed()).hexString
    }
}
