//
//  OrganizeTokensListItemPreviewProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListItemPreviewProvider {
    func singleSmallHeaderlessSection() -> [OrganizeTokensListSection] {
        return [
            .init(
                model: .init(id: UUID(), style: .invisible),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false),
                            isCustom: true
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func singleSmallSection() -> [OrganizeTokensListSection] {
        return [
            .init(
                model: .init(id: UUID(), style: .draggable(title: "Bitcoin Network")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false),
                            isCustom: true
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func singleMediumSection() -> [OrganizeTokensListSection] {
        return [
            .init(
                model: .init(id: UUID(), style: .draggable(title: "Bitcoin Network")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: false,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil,
                            isCustom: true,
                            customTokenColor: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: true,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(value: .tetherMock),
                            in: .ethereumClassic(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func singleLargeSection() -> [OrganizeTokensListSection] {
        return [
            .init(
                model: .init(id: UUID(), style: .invisible),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .arbitrum(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .litecoin,
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .stellar(curve: .ed25519_slip0010, testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereumPoW(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereumClassic(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoinCash,
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .binance(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .cardano(extended: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bsc(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .dogecoin,
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .polygon(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .avalanche(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .solana(curve: .ed25519_slip0010, testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: false,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .fantom(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: false,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .polkadot(curve: .ed25519_slip0010, testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .azero(curve: .ed25519_slip0010, testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .tron(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: true,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .optimism(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: true,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ton(curve: .ed25519_slip0010, testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .kava(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .cosmos(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func multipleSections() -> [OrganizeTokensListSection] {
        return [
            .init(
                model: .init(id: UUID(), style: .draggable(title: "Section #1")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil,
                            isCustom: false,
                            customTokenColor: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                model: .init(id: UUID(), style: .draggable(title: "Section #2")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil,
                            isCustom: true,
                            customTokenColor: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                model: .init(id: UUID(), style: .draggable(title: "Section #3")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil,
                            isCustom: false,
                            customTokenColor: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                model: .init(id: UUID(), style: .draggable(title: "Section #4")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil,
                            isCustom: true,
                            customTokenColor: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                model: .init(id: UUID(), style: .draggable(title: "Section #5")),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false),
                            isCustom: false
                        ),
                        balance: .loading(),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false),
                            isCustom: false
                        ),
                        balance: .empty,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil,
                            isCustom: false,
                            customTokenColor: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }
}

// MARK: - Convenience extensions

private extension OrganizeTokensListItemViewModel.Identifier {
    static func random() -> Self {
        return .init(
            walletModelId: .random(in: 0 ..< Int.max),
            inGroupedSection: .random()
        )
    }
}
