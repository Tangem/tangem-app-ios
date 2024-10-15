//
//  NEARNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct NEARNetworkProvider {
    private let baseURL: URL
    private let provider: NetworkProvider<NEARTarget>

    init(
        baseURL: URL,
        configuration: NetworkProviderConfiguration
    ) {
        self.baseURL = baseURL
        provider = NetworkProvider<NEARTarget>(configuration: configuration)
    }

    func getProtocolConfig() -> AnyPublisher<NEARNetworkResult.ProtocolConfig, Error> {
        return requestPublisher(for: .protocolConfig)
    }

    func getGasPrice() -> AnyPublisher<NEARNetworkResult.GasPrice, Error> {
        return requestPublisher(for: .gasPrice)
    }

    func getInfo(accountId: String) -> AnyPublisher<NEARNetworkResult.AccountInfo, Error> {
        return requestPublisher(for: .viewAccount(accountId: accountId))
    }

    func getAccessKeyInfo(
        accountId: String,
        publicKey: String
    ) -> AnyPublisher<NEARNetworkResult.AccessKeyInfo, Error> {
        return requestPublisher(for: .viewAccessKey(accountId: accountId, publicKey: publicKey))
    }

    func sendTransactionAsync(
        _ transaction: String
    ) -> AnyPublisher<NEARNetworkResult.TransactionSendAsync, Error> {
        return requestPublisher(for: .sendTransactionAsync(transaction: transaction))
    }

    func sendTransactionAwait(
        _ transaction: String
    ) -> AnyPublisher<NEARNetworkResult.TransactionSendAwait, Error> {
        return requestPublisher(for: .sendTransactionAwait(transaction: transaction))
    }

    func getTransactionStatus(
        accountId: String,
        transactionHash: String
    ) -> AnyPublisher<NEARNetworkResult.TransactionStatus, Error> {
        return requestPublisher(for: .transactionStatus(accountId: accountId, transactionHash: transactionHash))
    }

    private func requestPublisher<T: Decodable>(
        for target: NEARTarget.Target
    ) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(NEARTarget(baseURL: baseURL, target: target))
            .filterSuccessfulStatusCodes()
            .map(JSONRPC.Response<T, NEARNetworkResult.APIError>.self, using: decoder)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}

// MARK: - HostProvider protocol conformance

extension NEARNetworkProvider: HostProvider {
    var host: String {
        baseURL.hostOrUnknown
    }
}
