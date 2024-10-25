//
//  AptosNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct AptosNetworkProvider: HostProvider {
    // MARK: - HostProvider

    /// Blockchain API host
    var host: String {
        node.host
    }

    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: NetworkProvider<AptosProviderTarget>

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
    }

    // MARK: - Implementation

    func getAccountResources(address: String) -> AnyPublisher<[AptosResponse.AccountResource], Error> {
        let target = AptosProviderTarget(
            node: node,
            targetType: .accountsResources(address: address)
        )

        return requestPublisher(for: target)
    }

    func getGasUnitPrice() -> AnyPublisher<AptosResponse.Fee, Error> {
        let target = AptosProviderTarget(
            node: node,
            targetType: .estimateGasPrice
        )

        return requestPublisher(for: target)
    }

    func calculateUsedGasPriceUnit(transactionBody: AptosRequest.TransactionBody) -> AnyPublisher<[AptosResponse.SimulateTransactionBody], Error> {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        guard let data = try? encoder.encode(transactionBody) else {
            return .emptyFail
        }

        let target = AptosProviderTarget(
            node: node,
            targetType: .simulateTransaction(data: data)
        )

        return requestPublisher(for: target)
    }

    func submitTransaction(data: Data) -> AnyPublisher<AptosResponse.SubmitTransactionBody, Error> {
        let target = AptosProviderTarget(
            node: node,
            targetType: .submitTransaction(data: data)
        )

        return requestPublisher(for: target)
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: Decodable>(for target: AptosProviderTarget) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .mapError { moyaError -> Swift.Error in
                switch moyaError {
                case .statusCode(let response) where response.statusCode == 404 && target.isAccountsResourcesRequest:
                    return WalletError.noAccount(message: Localization.noAccountSendToCreate, amountToCreate: 0)
                default:
                    return moyaError
                }
            }
            .eraseToAnyPublisher()
    }
}
