//
//  CardanoNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardanoNetworkProvider: HostProvider {
    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error>
    func send(transaction: Data) -> AnyPublisher<String, Error>
}

extension CardanoNetworkProvider {
    func eraseToAnyCardanoNetworkProvider() -> AnyCardanoNetworkProvider {
        AnyCardanoNetworkProvider(self)
    }
}

class AnyCardanoNetworkProvider: CardanoNetworkProvider {
    var host: String { provider.host }

    private let provider: CardanoNetworkProvider

    init<P: CardanoNetworkProvider>(_ provider: P) {
        self.provider = provider
    }

    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        provider.getInfo(addresses: addresses, tokens: tokens)
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        provider.send(transaction: transaction)
    }
}

class CardanoNetworkService: MultiNetworkProvider, CardanoNetworkProvider {
    let providers: [AnyCardanoNetworkProvider]
    var currentProviderIndex: Int = 0

    init(providers: [AnyCardanoNetworkProvider]) {
        self.providers = providers
    }

    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        providerPublisher { $0.getInfo(addresses: ["addr1qxzah68yc5a5fyaz6pazzmuthvfwpnwcqlchxwgmskjukrw7n3ekrzf4fjhgz33gjnqcldugyqkgl6l0vylyazaryvush3qw95"], tokens: tokens) }
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher { $0.send(transaction: transaction) }
    }
}

struct CardanoAddressResponse: Hashable {
    let balance: UInt64
    let tokenBalances: [Token: UInt64]
    let recentTransactionsHashes: [String]
    let unspentOutputs: [CardanoUnspentOutput]
}

struct CardanoUnspentOutput: Hashable {
    let address: String
    let amount: UInt64
    let outputIndex: UInt64
    let transactionHash: String
    let assets: [Asset]
}

extension CardanoUnspentOutput {
    struct Asset: Hashable {
        let policyID: String
        /// Token/Asset symbol in hexadecimal format `ASCII` encoding e.g. `41474958 = AGIX`
        let assetNameHex: String
        let amount: UInt64
    }
}
