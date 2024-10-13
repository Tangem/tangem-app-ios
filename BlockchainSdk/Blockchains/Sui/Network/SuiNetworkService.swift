//
// SuiNetworkService.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

final class SuiNetworkService: MultiNetworkProvider {
    let providers: [SuiNetworkProvider]
    let balanceFetcher = SuiBalanceFetcher()
    var currentProviderIndex: Int
    
    init(providers: [SuiNetworkProvider]) {
        self.providers = providers
        self.currentProviderIndex = 0
    }
    
    func getBalance(address: String, coinType: SUIUtils.CoinType, cursor: String?) -> AnyPublisher<Result<[SuiGetCoins.Coin], Error>, Never> {
        return balanceFetcher
            .setupRequestPublisherBuilder { [weak self] nextAddress, nextCoin, nextCursor in
            guard let self else {
                return .anyFail(error: NetworkServiceError.notAvailable)
            }
            return self.providerPublisher { provider in
                provider
                    .getBalance(address: nextAddress, coin: nextCoin, cursor: nextCursor)
            }
        }
        .fetchBalance(address: address, coin: coinType.string, cursor: cursor)
    }
    
    func getReferenceGasPrice() -> AnyPublisher<SuiReferenceGasPrice, Error> {
        return providerPublisher { provider in
            provider
                .getReferenceGasPrice()
        }
    }
    
    func dryTransaction(transaction raw: String) -> AnyPublisher<SuiInspectTransaction, Error> {
        return providerPublisher { provider in
            provider
                .dryRunTransaction(transaction: raw)
        }
    }
    
    func sendTransaction(transaction raw: String, signature: String) -> AnyPublisher<SuiExecuteTransaction, Error> {
        return providerPublisher { provider in
            provider
                .sendTransaction(transaction: raw, signature: signature)
        }
    }
    
}
