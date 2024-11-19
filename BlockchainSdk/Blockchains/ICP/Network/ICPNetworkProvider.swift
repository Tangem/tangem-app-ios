//
//  ICPNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import IcpKit

struct ICPNetworkProvider: HostProvider {
    /// Blockchain API host
    var host: String {
        node.url.hostOrUnknown
    }

    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let network: NetworkProvider<ICPProviderTarget>

    private let responseParser: ICPResponseParser

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: NetworkProviderConfiguration,
        responseParser: ICPResponseParser
    ) {
        self.node = node
        network = .init(configuration: networkConfig)
        self.responseParser = responseParser
    }

    // MARK: - Implementation

    /// Fetch balance information
    /// - Parameter data: CBOR-encoded ICPRequestEnvelope
    /// - Returns: account balance
    func getBalance(data: Data) -> AnyPublisher<Decimal, Error> {
        let target = providerTarget(node: node, requestType: ICPRequestType.query.rawValue, requestData: data)
        return requestPublisher(for: target, map: responseParser.parseAccountBalanceResponse(_:))
    }

    /// Send transaction data message
    /// - Parameter data: CBOR-encoded ICPRequestEnvelope
    /// - Returns: Publisher signalling completion of operation
    func send(data: Data) -> AnyPublisher<Void, Error> {
        let target = providerTarget(node: node, requestType: ICPRequestType.call.rawValue, requestData: data)
        return requestPublisher(for: target, map: responseParser.parseTransferResponse(_:))
    }

    /// Check transaction state
    /// - Parameters:
    ///  - data: CBOR-encoded ICPRequestEnvelope
    ///  - paths: state tree paths for parsing response
    /// - Returns: Publisher for Latest block or none if trasaction is not completed
    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<UInt64?, Error> {
        let target = providerTarget(node: node, requestType: ICPRequestType.readState.rawValue, requestData: data)
        return requestPublisher(for: target) { [responseParser] data in
            try? responseParser.parseTransferStateResponse(data, paths: paths)
        }
    }

    // MARK: - Private Implementation

    private func providerTarget(node: NodeInfo, requestType: String, requestData: Data) -> ICPProviderTarget {
        ICPProviderTarget(
            node: node,
            canister: ICPSystemCanisters.ledger.string,
            requestType: requestType,
            requestData: requestData
        )
    }

    private func requestPublisher<T>(
        for target: ICPProviderTarget,
        map: @escaping (Data) throws -> T
    ) -> AnyPublisher<T, Error> {
        network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap { response in
                try map(response.data)
            }
            .mapError { _ in WalletError.empty }
            .eraseToAnyPublisher()
    }
}
