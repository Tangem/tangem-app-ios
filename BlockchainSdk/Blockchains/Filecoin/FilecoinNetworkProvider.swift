//
//  FilecoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class FilecoinNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }

    private let node: NodeInfo
    private let provider: NetworkProvider<FilecoinTarget>

    init(
        node: NodeInfo,
        configuration: NetworkProviderConfiguration
    ) {
        self.node = node
        provider = NetworkProvider<FilecoinTarget>(configuration: configuration)
    }

    func getActorInfo(address: String) -> AnyPublisher<FilecoinResponse.GetActorInfo, Error> {
        requestPublisher(for: .getActorInfo(address: address))
    }

    func getEstimateMessageGas(message: FilecoinMessage) -> AnyPublisher<FilecoinResponse.GetEstimateMessageGas, Error> {
        requestPublisher(for: .getEstimateMessageGas(message: message))
    }

    func submitTransaction(signedMessage: FilecoinSignedMessage) -> AnyPublisher<FilecoinResponse.SubmitTransaction, Error> {
        requestPublisher(for: .submitTransaction(signedMessage: signedMessage))
    }

    private func requestPublisher<T: Decodable>(for target: FilecoinTarget.FilecoinTargetType) -> AnyPublisher<T, Error> {
        provider.requestPublisher(FilecoinTarget(node: node, target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<T, JSONRPC.APIError>.self)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
