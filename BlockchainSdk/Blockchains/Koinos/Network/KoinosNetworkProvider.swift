//
//  KoinosNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 23.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine

class KoinosNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }

    private let node: NodeInfo
    private let provider: NetworkProvider<KoinosTarget>
    private let koinosNetworkParams: KoinosNetworkParams

    init(
        node: NodeInfo,
        koinosNetworkParams: KoinosNetworkParams,
        configuration: NetworkProviderConfiguration
    ) {
        self.node = node
        provider = NetworkProvider<KoinosTarget>(configuration: configuration)
        self.koinosNetworkParams = koinosNetworkParams
    }

    func getKoinBalance(address: String) -> AnyPublisher<KoinosMethod.ReadContract.Response, Error> {
        Result {
            try Koinos_Contracts_Token_balance_of_arguments.with {
                $0.owner = address.base58DecodedData
            }
            .serializedData()
            .base64URLEncodedString()
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { provider, args in
            provider.requestPublisher(
                for: .getKoinBalance(args: args),
                withResponseType: KoinosMethod.ReadContract.Response.self
            )
        }
        .eraseToAnyPublisher()
    }

    func getRC(address: String) -> AnyPublisher<KoinosMethod.GetAccountRC.Response, Error> {
        requestPublisher(
            for: .getRc(address: address),
            withResponseType: KoinosMethod.GetAccountRC.Response.self
        )
        .eraseToAnyPublisher()
    }

    func getResourceLimits() -> AnyPublisher<KoinosMethod.GetResourceLimits.Response, Error> {
        requestPublisher(
            for: .getResourceLimits,
            withResponseType: KoinosMethod.GetResourceLimits.Response.self
        )
        .eraseToAnyPublisher()
    }

    func getNonce(address: String) -> AnyPublisher<KoinosMethod.GetAccountNonce.Response, Error> {
        requestPublisher(
            for: .getNonce(address: address),
            withResponseType: KoinosMethod.GetAccountNonce.Response.self
        )
        .eraseToAnyPublisher()
    }

    func submitTransaction(transaction: KoinosProtocol.Transaction) -> AnyPublisher<KoinosMethod.SubmitTransaction.Response, Error> {
        requestPublisher(
            for: .submitTransaction(transaction: transaction),
            withResponseType: KoinosMethod.SubmitTransaction.Response.self
        )
        .eraseToAnyPublisher()
    }

    func getTransactions(transactionIDs: [String]) -> AnyPublisher<KoinosMethod.GetTransactions.Response, Error> {
        requestPublisher(
            for: .getTransactions(transactionIDs: transactionIDs),
            withResponseType: KoinosMethod.GetTransactions.Response.self
        )
        .eraseToAnyPublisher()
    }
}

private extension KoinosNetworkProvider {
    func requestPublisher<T: Decodable>(
        for target: KoinosTarget.KoinosTargetType,
        withResponseType: T.Type
    ) -> AnyPublisher<T, Error> {
        provider.requestPublisher(KoinosTarget(node: node, koinosNetworkParams: koinosNetworkParams, target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<T, JSONRPC.APIError>.self, using: .withSnakeCaseStrategy)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
