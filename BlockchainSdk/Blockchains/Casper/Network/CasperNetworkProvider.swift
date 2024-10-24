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
    
    // MARK: - Private Properties
    
    private let node: NodeInfo
    private let provider: NetworkProvider<CasperTarget>
    
    // MARK: - Init
    
    init(
        node: NodeInfo,
        configuration: NetworkProviderConfiguration
    ) {
        self.node = node
        provider = NetworkProvider<CasperTarget>(configuration: configuration)
    }
    
    // MARK: - Implementation
    
    func getBalance(address: String) -> AnyPublisher<CasperNetworkResult.Balance, Error> {
        requestPublisher(for: .getBalance(address: address))
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
