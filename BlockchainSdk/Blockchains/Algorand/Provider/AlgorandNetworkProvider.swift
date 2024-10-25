//
//  AlgorandNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct AlgorandNetworkProvider: HostProvider {
    // MARK: - HostProvider

    /// Blockchain API host
    var host: String {
        node.host
    }

    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: NetworkProvider<AlgorandProviderTarget>

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
    }

    // MARK: - Implementation

    func getAccount(address: String) -> AnyPublisher<AlgorandResponse.Account, Error> {
        let target = AlgorandProviderTarget(
            node: node,
            targetType: .getAccounts(address: address)
        )

        return requestPublisher(for: target)
    }

    func getTransactionParams() -> AnyPublisher<AlgorandResponse.TransactionParams, Error> {
        let target = AlgorandProviderTarget(
            node: node,
            targetType: .getTransactionParams
        )

        return requestPublisher(for: target)
    }

    func sendTransaction(data: Data) -> AnyPublisher<AlgorandResponse.TransactionResult, Error> {
        let target = AlgorandProviderTarget(
            node: node,
            targetType: .transaction(trx: data)
        )

        return requestPublisher(for: target)
    }

    func getPendingTransaction(txId: String) -> AnyPublisher<AlgorandResponse.PendingTransaction?, Error> {
        let target = AlgorandProviderTarget(
            node: node,
            targetType: .getPendingTransaction(txId: txId)
        )

        return requestPublisher(for: target)
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: Decodable>(for target: AlgorandProviderTarget) -> AnyPublisher<T, Error> {
        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .mapError { moyaError -> Swift.Error in
                if
                    let statusCode = moyaError.response?.statusCode,
                    Constants.knownAPIErrorCodes.contains(statusCode),
                    let decodeData = moyaError.response?.data {
                    let jsonDecodeError = try? JSONDecoder().decode(AlgorandResponse.Error.self, from: decodeData)
                    return jsonDecodeError ?? moyaError
                }

                return moyaError
            }
            .eraseToAnyPublisher()
    }
}

extension AlgorandNetworkProvider {
    enum Constants {
        static let knownAPIErrorCodes: [Int] = [400, 500, 503]
    }
}
