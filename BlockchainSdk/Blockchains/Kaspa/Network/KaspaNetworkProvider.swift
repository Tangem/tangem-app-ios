//
//  KaspaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkProvider: HostProvider {
    var host: String {
        url.hostOrUnknown
    }

    private let url: URL
    private let provider: NetworkProvider<KaspaTarget>

    init(url: URL, networkConfiguration: NetworkProviderConfiguration) {
        self.url = url
        provider = NetworkProvider<KaspaTarget>(configuration: networkConfiguration)
    }

    func currentBlueScore() -> AnyPublisher<KaspaBlueScoreResponse, Error> {
        requestPublisher(for: .blueScore)
    }

    func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        requestPublisher(for: .balance(address: address))
    }

    func utxos(address: String) -> AnyPublisher<[KaspaUnspentOutputResponse], Error> {
        requestPublisher(for: .utxos(address: address))
    }

    func send(transaction: KaspaTransactionRequest) -> AnyPublisher<KaspaTransactionResponse, Error> {
        requestPublisher(for: .transactions(transaction: transaction))
    }

    func transactionInfo(hash: String) -> AnyPublisher<KaspaTransactionInfoResponse, Error> {
        requestPublisher(for: .transaction(hash: hash))
    }

    func mass(data: KaspaTransactionData) -> AnyPublisher<KaspaMassResponse, Error> {
        requestPublisher(for: .mass(data: data))
    }

    func feeEstimate() -> AnyPublisher<KaspaFeeEstimateResponse, Error> {
        requestPublisher(for: .feeEstimate)
    }

    private func requestPublisher<T: Decodable>(for request: KaspaTarget.Request) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(KaspaTarget(request: request, baseURL: url))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .mapError { moyaError in
                if case .objectMapping = moyaError {
                    return WalletError.failedToParseNetworkResponse()
                }
                return moyaError
            }
            .eraseToAnyPublisher()
    }
}
