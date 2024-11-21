//
//  EstimationFeeAddressFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EstimationFeeAddressFactory {
    func makeAddress(for blockchain: Blockchain) throws -> String {
        switch blockchain {
        case .chia:
            // Can not generate and doesn't depend on destination
            return ""
        case .xrp,
             .stellar,
             .binance:
            // Doesn't depend on amount and destination
            return ""
        case .tezos:
            // Tezos has a fixed fee. See: `TezosFee.transaction`
            return ""
        case .internetComputer:
            // ICP has a fixed 0.0001 ICP fee
            return ""
        case .casper:
            // CSPR has a fixed 0.1 ICP fee
            return ""
        case .kaspa:
            return "kaspa:qyp2f0ust8wyvuvqrzajvehx5jyh43vcjgessjdkw9vyw6rww4fdlsgzysspfuq"
        case .hedera:
            // Doesn't depend on destination
            return ""
        case .radiant:
            return "1K8jBuCKzuwvFCjL7Qpqq69k1hnVXJ31Nc"
        case .ducatus:
            // Unsupported
            return ""
        // UTXO-like
        case .bitcoin:
            return "bc1qkrc5kmpq546wr2xk0errg58yw9jjq7thvhdk5k"
        case .litecoin:
            return "MSqjXH6toL4kHqsRo3mWaWMkhmiH9GQxLR"
        case .bitcoinCash:
            return "bitcoincash:qrn96yyxa93t6sqmehvls6746qafkcsuku6zmd9460"
        case .dogecoin:
            return "DRVD4B4YD9CBSjqaa3UfF42vSN6k2tJwhz"
        case .dash:
            return "Xqfekbgca2HDaXhrNYP2HTnuQ5go2E8dDE"
        case .ravencoin:
            return "RT5qKgXdmh9pqtz71cgfL834VfeXFVH1sG"
        // EVM-like
        case .ethereum, .ethereumPoW, .rsk, .polygon,
             .avalanche, .bsc, .fantom, .arbitrum, .gnosis, .optimism,
             .kava, .cronos, .telos, .octa, .shibarium, .disChain,
             .areon, .playa3ullGames, .pulsechain, .aurora, .manta,
             .zkSync, .moonbeam, .polygonZkEVM, .moonriver, .mantle,
             .flare, .taraxa, .base, .blast, .cyber, .energyWebEVM, .core, .canxium, .chiliz:
            return "0x52bb4012854f808CF9BAbd855e44E506dAf6C077"
        case .ethereumClassic:
            return "0xc49722a6f4Fe5A1347710dEAAa1fafF4c275689b"
        case .decimal:
            return "d0122a5qy59f7qge7d6hkz4u389qmd0dsrh6a7qnx"
        // Polkadot-like
        case .polkadot:
            return "15RRtiC2akPUE9FGqqa66awoAFz6XCnZiFUf34k2CHbLWNfC"
        case .kusama:
            return "CsNtwDXUzMR4ZKBQrXCfA6bBXQBFU1DDbtSwLAsaVr13sGs"
        case .azero:
            return "5DaWppqEJPc6BhFKD2NBC1ACXPDMPYfv2AQDB5uH5KT4mpef"
        case .joystream:
            return "j4SXkX46sABwjxeuzicd2e5m8gDu4ieoWHW3aggbBKkh4WvtF"
        case .bittensor:
            return "5HLcF8UkyCTK5oszoTxx8LKxEzmtEEfPWeAxCz5NiDjqWH9y"
        // Others
        case .cardano:
            return "addr1q95pg4z9tf26r5dwf72vmh62u3pr9sewq2waahyhpjzm3enz43pvhh0us3z0z5xen2skq200e67eu89s5v2s0sdh3fnsm9lknu"
        case .solana:
            return "9wuDg6Y4H4j86Kg5aUGrUeaBa3sAUzjMs37KbeGFnRuM"
        case .cosmos:
            return "cosmos1lhjvds604fvac32j4eygpr820lyc82dlyq70m5"
        case .tron:
            return "TA4Tkaj2nAJjkVbDHdUQDxYCbLfsZzS8pA"
        case .near:
            return "4a9fb267a005b7e923233b59aff1b73e577347a1ab36aa231a1880a91776c416"
        case .xdc:
            return "xdc9606Af4939f6F9fb9731A39a32B00aD966348ED6"
        case .veChain:
            return "0x1C5B4935709583758BE5b9ECeeBaf5cD6AFecF41"
        case .aptos:
            return "0x4626b7ef23fb2800a0e224e8249f47e0db3579070262da2a7efb0bc52c882867"
        case .algorand:
            return "CW6XDCKQAZUGAIOTGE2NEPYFFVW6H6IKFOTOF3W5WDUVHH4ZIDCIKYDPXY"
        // We have to generate a new dummy address for
        case .terraV1, .terraV2:
            return "terra1pfamr0t2daet92grdvxqex235q58qrx6xclldg"
        case .ton:
            return "EQAY92urFDKejoDRdi_EfRKLGB1JkGjD8z1inj_DhgBaD0Xo"
        case .koinos:
            return "1C423Vbd44zjghhJR5fKJdLFS3rgVFUc9A"
        case .sui:
            return "0xbca45e36a271e106546c89984108685215724e488570a0049a187c473cd521bc"
        case .filecoin:
            return "f1wxdu6d25dc4hmebdfgriswooum22plhmmpxibzq"
        case .sei:
            return "sei1lhjvds604fvac32j4eygpr820lyc82dlfv0ea4"
        case .energyWebX:
            return "5CogUCbb5PYYbEHhDVGDN6JRRYBkd4sFRVc4wwP8oy5Su34Z"
        }
    }
}
