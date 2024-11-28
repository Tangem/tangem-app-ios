//
// KaspaNetworkServiceKRC20.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 17.10.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkServiceKRC20: MultiNetworkProvider {
    let providers: [KaspaNetworkProviderKRC20]
    var currentProviderIndex: Int = 0

    private let blockchain: Blockchain

    init(providers: [KaspaNetworkProviderKRC20], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }

    func balance(address: String, tokens: [Token]) -> AnyPublisher<[Token: Result<KaspaBalanceResponseKRC20, Error>], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, token in
                networkService.providerPublisher(for: { provider in
                    provider.balance(address: address, token: token.contractAddress)
                        .retry(2)
                        .eraseToAnyPublisher()
                })
                .mapToResult()
                .setFailureType(to: Error.self)
                .map { (token, $0) }
                .eraseToAnyPublisher()
            }
            .collect()
            .map { $0.reduce(into: [Token: Result<KaspaBalanceResponseKRC20, Error>]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }
}
