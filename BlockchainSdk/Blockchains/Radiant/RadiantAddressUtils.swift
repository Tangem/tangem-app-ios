//
//  RadiantUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct RadiantAddressUtils {
    /*
     Specify electrum api network

     The hash function the server uses for script hashing. The client must use this function to hash pay-to-scripts to produce script hashes to send to the server. The default is “sha256”. “sha256” is currently the only acceptable value.

     More: https://electrumx.readthedocs.io/en/latest/protocol-basics.html#script-hashes
     */
    func prepareScriptHash(address: String) throws -> String {
        guard let addressKeyHash = WalletCore.BitcoinAddress(string: address)?.keyhash else {
            throw WalletError.empty
        }

        let scriptHashData = WalletCore.BitcoinScript.buildPayToPublicKeyHash(hash: addressKeyHash).data

        return Data(scriptHashData.sha256().reversed()).hexString
    }
}
