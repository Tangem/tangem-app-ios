//
//  RavencoinTestNetworkParams.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BitcoinCore

/// You can find this constants in the class `CTestNetParams` from
/// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp
class RavencoinTestNetworkParams: INetwork {
    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L421
    /// base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,111);
    /// Decimal(111) = UInt8(0x6F)
    let pubKeyHash: UInt8 = 0x6F

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L422
    /// base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,196);
    /// Decimal(196) = UInt8(0xC4)
    let scriptHash: UInt8 = 0xC4

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L423
    /// base58Prefixes[SECRET_KEY] = std::vector<unsigned char>(1,239);
    /// Decimal(239) = UInt8(0xEF)
    let privateKey: UInt8 = 0xEF

    let bech32PrefixPattern: String = "bc"
    let sigHash: SigHashType = .bitcoinAll

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L424
    /// base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x35, 0x87, 0xCF};
    let xPubKey: UInt32 = 0x043587cf

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L425
    /// base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x35, 0x83, 0x94};
    let xPrivKey: UInt32 = 0x04358394

    /// Protocol message header bytes
    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L337
    /// pchMessageStart[0] = 0x52; // R
    /// pchMessageStart[1] = 0x56; // V
    /// pchMessageStart[2] = 0x4E; // N
    /// pchMessageStart[3] = 0x54; // T
    let magic: UInt32 = 0x52564e54

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L341
    /// nDefaultPort = 18770;
    let port: UInt32 = 18770

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L428
    /// Raven BIP44 cointype in testnet
    /// nExtCoinType = 1;
    let coinType: UInt32 = 1

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/policy/policy.h#L48
    /// static const unsigned int DUST_RELAY_TX_FEE = 3000;
    let dustRelayTxFee = 3000

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L417
    /// vSeeds.emplace_back("seed-testnet-raven.bitactivate.com", false);
    /// vSeeds.emplace_back("seed-testnet-raven.ravencoin.com", false);
    /// vSeeds.emplace_back("seed-testnet-raven.ravencoin.org", false);
    let dnsSeeds = [
        "seed-testnet-raven.bitactivate.com",
        "seed-testnet-raven.ravencoin.com",
        "seed-testnet-raven.ravencoin.org",
    ]

    init() {}
}
