//
//  DashTestNetworkParams.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 09.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BitcoinCore

/// You can find this constants in the class `CMainParams` from
/// /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L535
class DashTestNetworkParams: INetwork {
    let protocolVersion: Int32 = 70214

    let bundleName = "DashKit"

    let maxBlockSize: UInt32 = 1_000_000_000
    let pubKeyHash: UInt8 = 0x8c
    let privateKey: UInt8 = 0x80
    let scriptHash: UInt8 = 0x13
    let bech32PrefixPattern: String = "bc"
    let xPubKey: UInt32 = 0x0488b21e
    let xPrivKey: UInt32 = 0x0488ade4
    /// Protocol message header bytes
    let magic: UInt32 = 0xcee2caff
    let port: UInt32 = 19999
    let coinType: UInt32 = 1
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true

    let dnsSeeds = [
        "testnet-seed.dashdot.io",
        "test.dnsseed.masternode.io"
    ]

    // https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L36
    let dustRelayTxFee = 1000
}
