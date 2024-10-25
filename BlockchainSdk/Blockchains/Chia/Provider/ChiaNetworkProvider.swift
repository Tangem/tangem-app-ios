//
//  ChiaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

struct ChiaNetworkProvider: HostProvider {
    // MARK: - HostProvider

    /// Blockchain API host
    var host: String {
        node.host
    }

    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: NetworkProvider<ChiaProviderTarget>

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
    }

    // MARK: - Implementation

    func getUnspents(puzzleHash: String) -> AnyPublisher<ChiaCoinRecordsResponse, Error> {
        let target = ChiaProviderTarget(
            node: node,
            targetType: .getCoinRecordsBy(puzzleHashBody: .init(puzzleHash: puzzleHash))
        )

        return requestPublisher(for: target)
    }

    func sendTransaction(body: ChiaTransactionBody) -> AnyPublisher<ChiaSendTransactionResponse, Error> {
        let target = ChiaProviderTarget(
            node: node,
            targetType: .sendTransaction(body: body)
        )

        return requestPublisher(for: target)
    }

    func getFeeEstimate(body: ChiaFeeEstimateBody) -> AnyPublisher<ChiaEstimateFeeResponse, Error> {
        let target = ChiaProviderTarget(
            node: node,
            targetType: .getFeeEstimate(body: body)
        )

        return requestPublisher(for: target)
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: ChiaStatusResponse>(for target: ChiaProviderTarget) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .tryMap { response in
                guard response.success else {
                    throw WalletError.empty
                }

                return response
            }
            .mapError { error in
                return WalletError.failedToParseNetworkResponse()
            }
            .eraseToAnyPublisher()
    }
}
