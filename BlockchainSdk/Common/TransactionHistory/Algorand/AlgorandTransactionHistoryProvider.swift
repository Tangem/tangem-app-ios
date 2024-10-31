//
//  AlgorandHistoryProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AlgorandTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
    Mapper.Response == [AlgorandTransactionHistory.Response.Item] {
    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: NetworkProvider<AlgorandIndexProviderTarget>
    private let mapper: Mapper

    private var page: TransactionHistoryLinkedPage?

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration,
        mapper: Mapper
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
        self.mapper = mapper
    }
}

// MARK: - TransactionHistoryProvider

extension AlgorandTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        page == nil || (page?.next != nil)
    }

    var description: String {
        return objectDescription(
            self,
            userInfo: [
                "nextToken": page?.next ?? "-",
            ]
        )
    }

    func reset() {
        page = nil
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        let target = AlgorandIndexProviderTarget(
            node: node,
            targetType: .getTransactions(address: request.address, limit: request.limit, next: page?.next)
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(AlgorandTransactionHistory.Response.self, using: decoder)
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                let records = try provider.mapper.mapToTransactionRecords(
                    response.transactions,
                    walletAddress: request.address,
                    amountType: .coin
                )
                .filter { record in
                    provider.shouldBeIncludedInHistory(
                        amountType: request.amountType,
                        record: record
                    )
                }

                provider.page = .init(next: response.nextToken)

                return .init(records: records)
            }
            .mapError { moyaError -> Swift.Error in
                return WalletError.failedToParseNetworkResponse()
            }
            .eraseToAnyPublisher()
    }
}
