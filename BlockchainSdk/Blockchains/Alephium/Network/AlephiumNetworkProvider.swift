//
//  AlephiumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct AlephiumNetworkProvider: HostProvider {
    /// Blockchain API host
    var host: String {
        node.url.hostOrUnknown
    }

    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: NetworkProvider<AlephiumProviderTarget>

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
    }

    // MARK: - Implementation

    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        requestPublisher(for: .init(node: node, targetType: .getBalance(address: address)))
    }
    
    func getUTXOs(address: String) -> AnyPublisher<AlephiumNetworkResponse.UTXOs, Error> {
        requestPublisher(for: .init(node: node, targetType: .getUTXO(address: address)))
    }
    
    func buildTransaction(
        transfer: AlephiumNetworkRequest.BuildTransferTx
    ) -> AnyPublisher<AlephiumNetworkResponse.BuildTransferTxResult, Error> {
        requestPublisher(for: .init(node: node, targetType: .buildTransaction(transfer)))
    }
    
    func submit(
        transaction: AlephiumNetworkRequest.Submit
    ) -> AnyPublisher<AlephiumNetworkResponse.Submit, Error> {
        requestPublisher(for: .init(node: node, targetType: .submitTransaction(transaction)))
    }
    
    func transactionStatus(by id: String) -> AnyPublisher<AlephiumNetworkResponse.Status, Error> {
        requestPublisher(for: .init(node: node, targetType: .transactionStatus(txId: id)))
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: Decodable>(for target: AlephiumProviderTarget) -> AnyPublisher<T, any Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .mapError { _ in WalletError.empty }
            .eraseToAnyPublisher()
    }
}
