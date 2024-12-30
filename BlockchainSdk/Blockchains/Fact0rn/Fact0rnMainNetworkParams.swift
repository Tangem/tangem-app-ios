//
//  Fact0rnMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 25.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore

/// You can find this constants in the class `CMainParams` from
/// https://gitlab.com/cloreai-public/blockchain
///
/// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp
class Fact0rnMainNetworkParams: INetwork {
    let pubKeyHash: UInt8 = 0x00
    let privateKey: UInt8 = 0x80
    let scriptHash: UInt8 = 0x05
    let bech32PrefixPattern: String = "fact"
    let xPubKey: UInt32 = 0x0488b21e
    let xPrivKey: UInt32 = 0x0488ade4
    let magic: UInt32 = 0xf9beb4d9
    let port: UInt32 = 8333
    let coinType: UInt32 = 0
    let sigHash: SigHashType = .bitcoinAll

    let dnsSeeds = [
        "seed.bitcoin.sipa.be", // Pieter Wuille
        "dnsseed.bluematt.me", // Matt Corallo
        "dnsseed.bitcoin.dashjr.org", // Luke Dashjr
        "seed.bitcoinstats.com", // Chris Decker
        "seed.bitnodes.io", // Addy Yeow
        "seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
    ]

    let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
}
