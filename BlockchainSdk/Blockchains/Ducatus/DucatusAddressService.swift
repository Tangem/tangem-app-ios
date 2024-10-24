//
//  DucatusAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

class DucatusNetworkParams: INetwork {
    let bundleName = "BitcoinKit"

    let pubKeyHash: UInt8 = 0x31 //addressHeader
    let privateKey: UInt8 = 0xB0 //dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x33 //p2shHeader
    let bech32PrefixPattern: String = "duc" //segwitAddressHrp
    let xPubKey: UInt32 = 0x0488B21E //bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x0488ADE4 //bip32HeaderP2PKHpriv
    let magic: UInt32 = 0xfbc0b6db //packetMagic
    let port: UInt32 = 9333 //port
    let coinType: UInt32 = 0
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true

    let dnsSeeds = [
        "seed.bitcoin.sipa.be",         // Pieter Wuille
        "dnsseed.bluematt.me",          // Matt Corallo
        "dnsseed.bitcoin.dashjr.org",   // Luke Dashjr
        "seed.bitcoinstats.com",        // Chris Decker
        "seed.bitnodes.io",             // Addy Yeow
        "seed.bitcoin.jonasschnelli.ch",// Jonas Schnelli
    ]

    let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
}
