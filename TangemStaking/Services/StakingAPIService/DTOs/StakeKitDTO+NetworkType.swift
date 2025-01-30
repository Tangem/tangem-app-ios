//
//  StakeKitDTO+NetworkType.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum StakeKitNetworkType: String, Hashable, Codable {
    case ethereum
    case ethereumGoerli = "ethereum-goerli"
    case ethereumHolesky = "ethereum-holesky"
    case arbitrum
    case base
    case gnosis
    case optimism
    case polygon
    case starknet
    case zksync
    case avalancheC = "avalanche-c"
    case avalancheCAtomic = "avalanche-c-atomic"
    case avalancheP = "avalanche-p"
    case binance
    case celo
    case fantom
    case harmony
    case moonriver
    case okc
    case viction
    case agoric
    case akash
    case axelar
    case bandProtocol = "band-protocol"
    case bitsong
    case canto
    case chihuahua
    case comdex
    case coreum
    case cosmos
    case crescent
    case cronos
    case cudos
    case desmos
    case dydx
    case evmos
    case fetchAi = "fetch-ai"
    case gravityBridge = "gravity-bridge"
    case injective
    case irisnet
    case juno
    case kava
    case kiNetwork = "ki-network"
    case marsProtocol = "mars-protocol"
    case nym
    case okexChain = "okex-chain"
    case onomy
    case osmosis
    case persistence
    case quicksilver
    case regen
    case secret
    case sentinel
    case sommelier
    case stafi
    case stargaze
    case stride
    case teritori
    case tgrade
    case umee
    case polkadot
    case kusama
    case westend
    case binanceBeacon = "binancebeacon"
    case near
    case solana
    case tezos
    case ton
    case tron
}
