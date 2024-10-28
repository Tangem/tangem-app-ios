//
//  TezosJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class TezosJsonRpcProvider: HostProvider {
    let host: String
    private let provider: NetworkProvider<TezosTarget>

    init(host: String, configuration: NetworkProviderConfiguration) {
        self.host = host
        provider = NetworkProvider<TezosTarget>(configuration: configuration)
    }

    func getInfo(address: String) -> AnyPublisher<TezosAddressResponse, Error> {
        requestPublisher(for: TezosTarget(host: host, endpoint: .addressData(address: address)))
            .map(TezosAddressResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func checkPublicKeyRevealed(address: String) -> AnyPublisher<Bool, Error> {
        requestPublisher(for: TezosTarget(host: host, endpoint: .managerKey(address: address)))
            .mapString()
            .cleanString()
            .map { $0 == "null" ? false : true }
            .tryCatch { error -> AnyPublisher<Bool, Error> in
                if case MoyaError.stringMapping = error {
                    return Just(false)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }

    func getHeader() -> AnyPublisher<TezosHeaderResponse, Error> {
        requestPublisher(for: TezosTarget(host: host, endpoint: .getHeader))
            .map(TezosHeaderResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func forgeContents(headerHash: String, contents: [TezosOperationContent]) -> AnyPublisher<String, Error> {
        let body = TezosForgeBody(branch: headerHash, contents: contents)

        return requestPublisher(for: TezosTarget(host: host, endpoint: .forgeOperations(body: body)))
            .mapString()
            .cleanString()
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func checkTransaction(
        protocol: String,
        hash: String,
        contents: [TezosOperationContent],
        signature: String
    ) -> AnyPublisher<Response, Error> {
        let body = TezosPreapplyBody(
            protocol: `protocol`,
            branch: hash,
            contents: contents,
            signature: signature
        )

        return requestPublisher(for: TezosTarget(host: host, endpoint: .preapplyOperations(body: [body])))
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func sendTransaction(_ transaction: String) -> AnyPublisher<Response, Error> {
        requestPublisher(for: TezosTarget(host: host, endpoint: .sendTransaction(tx: transaction)))
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    private func requestPublisher(for target: TezosTarget) -> AnyPublisher<Response, MoyaError> {
        provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .eraseToAnyPublisher()
    }
}
