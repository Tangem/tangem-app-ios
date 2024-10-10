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
    public let protocolVersion: Int32 = 70214

    public let bundleName = "DashKit"

    public let maxBlockSize: UInt32 = 2_000_000_000
    public let pubKeyHash: UInt8 = 0x4c
    public let privateKey: UInt8 = 0x80
    public let scriptHash: UInt8 = 0x10
    public let bech32PrefixPattern: String = "bc"
    
    //  https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L457
    public let xPubKey: UInt32 = 0x0488b21e
    
    //  https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L459
    public let xPrivKey: UInt32 = 0x0488ade4
    
    /// Protocol message header bytes
    /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L430
    public let magic: UInt32 = 0xbf0c6bbd
    
    /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L434
    public let port: UInt32 = 9999
    
    /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L462
    public let coinType: UInt32 = 5
    
    public let sigHash: SigHashType = .bitcoinAll
    public var syncableFromApi: Bool = true

    public let dnsSeeds = [
        "x5.dnsseed.dash.org",
        "x5.dnsseed.dashdot.io",
        "dnsseed.masternode.io",
    ]

    // https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L38
    public let dustRelayTxFee = 3000
    public init() {}
}
