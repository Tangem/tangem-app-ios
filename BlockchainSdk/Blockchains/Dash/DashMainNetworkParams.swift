//
//  DashMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BitcoinCore

/// You can find this constants in the class `CMainParams` from
/// /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L327
class DashMainNetworkParams: INetwork {
    let protocolVersion: Int32 = 70214

    let bundleName = "DashKit"

    let maxBlockSize: UInt32 = 2_000_000_000
    let pubKeyHash: UInt8 = 0x4c
    let privateKey: UInt8 = 0x80
    let scriptHash: UInt8 = 0x10
    let bech32PrefixPattern: String = "bc"

    //  https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L457
    let xPubKey: UInt32 = 0x0488b21e

    //  https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L459
    let xPrivKey: UInt32 = 0x0488ade4

    /// Protocol message header bytes
    /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L430
    let magic: UInt32 = 0xbf0c6bbd

    /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L434
    let port: UInt32 = 9999

    /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L462
    let coinType: UInt32 = 5

    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true

    let dnsSeeds = [
        "x5.dnsseed.dash.org",
        "x5.dnsseed.dashdot.io",
        "dnsseed.masternode.io",
    ]

    // https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L38
    let dustRelayTxFee = 3000
    init() {}
}
