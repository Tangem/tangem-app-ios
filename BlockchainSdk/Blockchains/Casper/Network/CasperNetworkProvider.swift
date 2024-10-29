//
//  CasperNetworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class CasperNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }

    private let node: NodeInfo

    // TODO: -
    private let provider: NetworkProvider<CasperTarget>

    init(
        node: NodeInfo,
        configuration: NetworkProviderConfiguration
    ) {
        self.node = node
        provider = NetworkProvider<CasperTarget>(configuration: configuration)
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: Decodable>(for target: CasperTarget.TargetType) -> AnyPublisher<T, Error> {
        provider.requestPublisher(CasperTarget(node: node))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<T, JSONRPC.APIError>.self)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
