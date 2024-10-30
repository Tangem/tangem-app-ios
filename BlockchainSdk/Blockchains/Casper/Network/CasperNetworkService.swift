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
    // MARK: - MultiNetwork Provider
    
    var currentProviderIndex: Int = 0
    
    // MARK: - Properties
    
    let providers: [CasperNetworkProvider]
    let blockchainDecimalValue: Decimal
    
    // MARK: - Init

    init(providers: [CasperNetworkProvider], blockchainDecimalValue: Decimal) {
        self.providers = providers
        self.blockchainDecimalValue = blockchainDecimalValue
    }
    
    // MARK: - Implementation

    func getBalance(address: String) -> AnyPublisher<CasperBalance, Error> {
        return providerPublisher { provider in
            return provider
                .getBalance(address: "01f03bbc42a3d5901c7232987ba84ab2c6d210973a0cfe742284dcb1d8b4cbe1c3")
                .withWeakCaptureOf(self)
                .tryMap { service, result in
                    guard let balanceValue = Decimal(string: result.balance) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    let decimalBalanceValue = balanceValue / service.blockchainDecimalValue
                    return .init(value: decimalBalanceValue)
                }
                .tryCatch { error -> AnyPublisher<CasperBalance, Error> in
                    if let error = error as? JSONRPC.APIError, error.code == Constants.ERROR_CODE_QUERY_FAILED {
                        return .anyFail(
                            error: WalletError.noAccount(
                                message: Localization.noAccountSendToCreate,
                                amountToCreate: 0
                            )
                        )
                    }
                    return .anyFail(error: error)
                }
                .eraseToAnyPublisher()
        }
    }
}

extension CasperNetworkService {
    enum Constants {
        static let ERROR_CODE_QUERY_FAILED = -32003
    }
}
