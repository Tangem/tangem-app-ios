//
//  CasperNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CasperNetworkService: MultiNetworkProvider {
    // MARK: - Properties
    
    let providers: [CasperNetworkProvider]
    var currentProviderIndex: Int = 0
    
    // MARK: - Init

    init(providers: [CasperNetworkProvider]) {
        self.providers = providers
    }
    
    // MARK: - Implementation

    func getBalance(address: String) -> AnyPublisher<CasperBalance, Error> {
        return providerPublisher { provider in
            return provider
                .getBalance(address: address)
                .tryMap { result in
                    guard let balanceValue = Decimal(string: result.balance) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    return .init(value: balanceValue)
                }
                .eraseToAnyPublisher()
        }
    }
}
