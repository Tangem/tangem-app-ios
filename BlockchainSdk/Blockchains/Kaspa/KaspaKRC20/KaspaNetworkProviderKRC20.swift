//
// KaspaNetworkProviderKRC20.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 17.10.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkProviderKRC20: HostProvider {
    var host: String {
        url.hostOrUnknown
    }

    private let url: URL
    private let provider: NetworkProvider<KaspaTargetKRC20>

    init(url: URL, networkConfiguration: NetworkProviderConfiguration) {
        self.url = url
        provider = NetworkProvider<KaspaTargetKRC20>(configuration: networkConfiguration)
    }

    func balance(address: String, token: String) -> AnyPublisher<KaspaBalanceResponseKRC20, Error> {
        requestPublisher(for: .balance(address: address, token: token))
    }

    private func requestPublisher<T: Decodable>(for request: KaspaTargetKRC20.Request) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(KaspaTargetKRC20(request: request, baseURL: url))
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
