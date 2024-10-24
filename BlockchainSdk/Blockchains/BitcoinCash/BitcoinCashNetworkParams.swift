//
//  BitcoinCashNetworkParams.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

class BitcoinCashNetworkParams: INetwork {
    let bundleName = "BitcoinKit"

    let pubKeyHash: UInt8 = 0x00 //addressHeader
    let privateKey: UInt8 = 0x80 //dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x05 //p2shHeader
    let bech32PrefixPattern: String = "bitcoincash" //segwitAddressHrp
    let xPubKey: UInt32 = 0x0488b21e //bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x0488ade4 //bip32HeaderP2PKHpriv
    let magic: UInt32 = 0xe3e1f3e8 //packetMagic
    let port: UInt32 = 8333 //port
    let coinType: UInt32 = 145
    let sigHash: SigHashType = .bitcoinCashAll
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

class BitcoinCashTestNetworkParams: INetwork {
    let bundleName = "BitcoinCashKit"
    
    let maxBlockSize: UInt32 = 32 * 1024 * 1024
    let pubKeyHash: UInt8 = 0x6f
    let privateKey: UInt8 = 0xef
    let scriptHash: UInt8 = 0xc4
    let bech32PrefixPattern: String = "bchtest"
    let xPubKey: UInt32 = 0x043587cf
    let xPrivKey: UInt32 = 0x04358394
    let magic: UInt32 = 0xf4e5f3f4
    let port: UInt32 = 18333
    let coinType: UInt32 = 1
    let sigHash: SigHashType = .bitcoinCashAll
    var syncableFromApi: Bool = true
    
    let dnsSeeds = [
        "testnet-seed.bitcoinabc.org",
        "testnet-seed-abc.bitcoinforks.org"
    ]
    
    let dustRelayTxFee = 1000    // https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
}
