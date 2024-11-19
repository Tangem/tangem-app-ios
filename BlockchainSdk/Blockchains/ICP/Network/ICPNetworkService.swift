//
//  ICPNetworkService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import IcpKit
import TangemSdk

final class ICPNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [ICPNetworkProvider]
    var currentProviderIndex: Int = 0

    private var blockchain: Blockchain

    // MARK: - Init

    init(providers: [ICPNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }

    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        guard let balanceRequestData = try? makeBalanceRequestData(address: address) else {
            return .anyFail(error: WalletError.empty).eraseToAnyPublisher()
        }
        return providerPublisher { [blockchain] provider in
            provider
                .getBalance(data: balanceRequestData)
                .map { result in
                    result / blockchain.decimalValue
                }
                .eraseToAnyPublisher()
        }
    }

    func send(data: Data) -> AnyPublisher<Void, Error> {
        providerPublisher { provider in
            provider
                .send(data: data)
        }
    }

    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<UInt64, Error> {
        providerPublisher { provider in
            provider
                .readState(data: data, paths: paths)
        }
        // we need custom retry logic here:
        // if publisher retruns nil result here (which is totally valid response,
        // because blockchain may not return any data before transaction execution)
        // we need to retry previous request using the same network provider after delay
        .mapToResult()
        .flatMap { result -> AnyPublisher<Result<UInt64, Error>, Error> in
            switch result {
            case .success(.some(let value)):
                .justWithError(output: .success(value))
            case .success(nil):
                Fail(error: WalletError.empty)
                    .delay(
                        for: .milliseconds(Constants.readStateRetryDelayMilliseconds),
                        scheduler: DispatchQueue.main
                    )
                    .eraseToAnyPublisher()
            case .failure(let error):
                .justWithError(output: .failure(error))
            }
        }
        .retry(Constants.readStateRetryCount)
        .tryMap { result -> UInt64 in
            try result.get()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private implementation

    private func makeBalanceRequestData(address: String) throws -> Data {
        let envelope = ICPRequestEnvelope(
            content: ICPRequestBuilder.makeCallRequestContent(
                method: .balance(account: Data(hex: address)),
                requestType: .query,
                date: Date(),
                nonce: try CryptoUtils.icpNonce()
            )
        )
        return try envelope.cborEncoded()
    }
}

private extension ICPNetworkService {
    enum Constants {
        static let readStateRetryCount = 10
        static let readStateRetryDelayMilliseconds = 750
    }
}

extension CryptoUtils {
    static func icpNonce() throws -> Data {
        try generateRandomBytes(count: 32)
    }
}
