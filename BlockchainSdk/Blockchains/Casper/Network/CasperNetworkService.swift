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
        providerPublisher { provider in
            provider
                .getBalance(address: address)
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

    func putDeploy(rawData: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider
                .putDeploy(rawJSON: rawData)
                .withWeakCaptureOf(self)
                .tryMap { service, result in
                    return result.deployHash
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
