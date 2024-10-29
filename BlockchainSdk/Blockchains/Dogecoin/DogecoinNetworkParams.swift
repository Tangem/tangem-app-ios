//
//  DogecoinNetworkParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 25/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

class DogecoinNetworkParams: INetwork {
    let pubKeyHash: UInt8 = 0x1E // addressHeader
    let privateKey: UInt8 = 0x9E // dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x16 // p2shHeader
    let bech32PrefixPattern: String = "D" // segwitAddressHrp
    let xPubKey: UInt32 = 0x02FACAFD // bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x02FAC398 // bip32HeaderP2PKHpriv
    let magic: UInt32 = 0xC0C0C0C0 // packetMagic
    let port: UInt32 = 22556 // port
    let coinType: UInt32 = 0
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true

    let dnsSeeds = [
        "seed.multidoge.org",
        "seed2.multidoge.org",
        "seed.doger.dogecoin.com",
    ]

    let dustRelayTxFee: Int = 1_000_000 // 0.01 DOGE
}
