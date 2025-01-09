//
//  Fact0rnMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 11.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore

// Data is taken from:
// https://github.com/FACT0RN/FACT0RN/blob/main/src/chainparams.cpp#L81
final class Fact0rnMainNetworkParams: INetwork {
    // base58Prefixes[PUBKEY_ADDRESS] = {0}
    let pubKeyHash: UInt8 = 0

    // base58Prefixes[SECRET_KEY] = {128}
    let privateKey: UInt8 = 128

    // base58Prefixes[SCRIPT_ADDRESS] = {5}
    let scriptHash: UInt8 = 5

    // bech32_hrp
    let bech32PrefixPattern: String = "fact"

    // base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x88, 0xB2, 0x1E}
    let xPubKey: UInt32 = 0x0488B21E

    // base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x88, 0xAD, 0xE4}
    let xPrivKey: UInt32 = 0x0488ADE4

    // pchMessageStart = {0xca, 0xfe, 0xca, 0xfe}
    let magic: UInt32 = 0xCAFECACA

    // nDefaultPort
    let port: UInt32 = 30030

    // DNS seeds are not specified in C++ code
    let dnsSeeds: [String] = []

    // https://github.com/FACT0RN/FACT0RN/blob/d02b33f3d5ce8a4be57fdb8c8b0bc3cb51760116/src/policy/policy.h#L54
    let dustRelayTxFee: Int = 3000

    // Genesis block creation parameter 2375LL
    let coinType: UInt32 = 2375

    // Assuming the standard "ALL" for SigHash type
    let sigHash: BitcoinCore.SigHashType = .bitcoinAll
}
