//
//  CosmosChain.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

enum CosmosChain {
    case cosmos(testnet: Bool)
    case terraV1
    case terraV2
    case sei(testnet: Bool)
    // ancient testnet network, we only use it for unit tests
    case gaia
}

// Keplr is a Cosmos network software wallet
// Keplr registry contains lots of goodies, for example:
// https://github.com/chainapsis/keplr-chain-registry/blob/main/cosmos/cosmoshub.json
extension CosmosChain {
    
    // Either feeCurrencies/coinMinimalDenom from Keplr registry
    // or
    // params/bond_denom field from /cosmos/staking/v1beta1/params request
    var smallestDenomination: String {
        switch self {
        case .cosmos:
            return "uatom"
        case .terraV1, .terraV2:
            return "uluna"
        case .gaia:
            return "muon"
        case .sei:
            return "usei"
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .cosmos(let testnet):
            return .cosmos(testnet: testnet)
        case .terraV1:
            return .terraV1
        case .terraV2:
            return .terraV2
        case .gaia:
            return .cosmos(testnet: true)
        case .sei(let isTestnet):
            return .sei(testnet: isTestnet)
        }
    }
    
    // Either chainId from Keplr registry
    // or
    // node_info/network field from /node_info request
    var chainID: String {
        switch self {
        case .cosmos(let testnet):
            return testnet ? "theta-testnet-001" : "cosmoshub-4"
        case .terraV1:
            return "columbus-5"
        case .terraV2:
            return "phoenix-1"
        case .gaia:
            return "gaia-13003"
        case .sei(let isTestnet):
            return isTestnet ? "atlantic-2" : "pacific-1"
        }
    }
    
    // For some chains gas prices are hardcoded with the same value for all fee levels
    var allowsFeeSelection: Bool {
        switch self {
        case .cosmos, .gaia, .terraV2, .sei:
            return true
        case .terraV1:
            return false
        }
    }
    
    // feeCurrencies/gasPriceStep field from Keplr registry
    func gasPrices(for amountType: Amount.AmountType) -> [Double] {
        switch self {
        case .cosmos:
            return [
                0.01,
                0.025,
                0.03,
            ]
        case .terraV1:
            if case .coin = amountType {
                return [
                    28.325,
                ]
            } else {
                return [
                    1,
                ]
            }
        case .terraV2:
            return [
                0.015,
                0.025,
                0.040,
            ]
        case .sei(let isTestnet):
            return isTestnet ? [0.08] : [0.02, 0.02, 0.04]
        case .gaia:
            fatalError()
        }
    }
    
    // Often times the value specified in Keplr is not enough:
    // >>> out of gas in location: WriteFlat; gasWanted: 76012, gasUsed: 76391: out of gas
    // >>> out of gas in location: ReadFlat; gasWanted: 124626, gasUsed: 125279: out of gas
    // Default multiplier value is 1
    var gasMultiplier: UInt64 {
        switch self {
        case .cosmos, .gaia:
            return 2
        case .terraV1:
            // Since 2024/07/29, there have been multiple reports of failed Terra Classic transactions due to
            // an incorrect gas estimation (calculated on the blockchain).
            // Therefore, we have to raise `gasMultiplier` once again as a workaround.
            return 5
        case .terraV2:
            return 2
        case .sei:
            return 2
        }
    }
    
    // We use a formula to calculate the fee, by multiplying estimated gas by gas price.
    // But sometimes this is not enough:
    // >>> insufficient fees; got: 1005uluna required: 1006uluna: insufficient fee
    // Default multiplier value is 1
    var feeMultiplier: Double {
        switch self {
        case .cosmos, .gaia:
            return 1
        case .terraV1, .terraV2, .sei:
            return 1.5
        }
    }
    
    var coin: CoinType {
        switch self {
        case .cosmos, .gaia:
            return .cosmos
        case .terraV1:
            return .terra
        case .terraV2:
            return .terraV2
        case .sei:
            return .sei
        }
    }
    
    var allowCW20Tokens: Bool {
        switch self {
        case .terraV2, .sei:
            return true
        case .cosmos, .terraV1, .gaia:
            return false
        }
    }
    
    func tokenDenomination(contractAddress: String, tokenCurrencySymbol: String) -> String? {
        switch self {
        case .terraV1:
            switch contractAddress {
            case "uusd":
                return "uusd"
            default:
                return nil
            }
        case .terraV2:
            return tokenCurrencySymbol
        case .cosmos, .gaia, .sei:
            return nil
        }
    }
    
    
    func tokenFeeDenomination(contractAddress: String, tokenCurrencySymbol: String) -> String? {
        switch self {
        case .terraV1:
            switch contractAddress {
            case "uusd":
                return "uusd"
            default:
                return nil
            }
        case .terraV2, .sei:
            return smallestDenomination
        case .cosmos, .gaia:
            return nil
        }
    }
    
    var taxPercentByContractAddress: [String: Decimal] {
        switch self {
        case .terraV1:
            return [
                "uusd": 0.2,
            ]
        case .cosmos, .gaia, .terraV2, .sei:
            return [:]
        }
    }
    
    func extraFee(for amount: Decimal) -> Decimal? {
        switch self {
        case .terraV1:
            // Stability or "spread" fee. Applied to both main currency and tokens
            // https://classic-docs.terra.money/docs/learn/fees.html#spread-fee
            let minimumSpreadFeePercentage: Decimal = 0.5
            return amount * 0.01 * minimumSpreadFeePercentage
        case .cosmos, .terraV2, .gaia, .sei:
            return nil
        }
    }
}
