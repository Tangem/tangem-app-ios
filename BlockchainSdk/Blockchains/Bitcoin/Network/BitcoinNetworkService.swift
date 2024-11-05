//
//  BitcoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk

class BitcoinNetworkService: MultiNetworkProvider, BitcoinNetworkProvider {
    let providers: [AnyBitcoinNetworkProvider]
    var currentProviderIndex: Int = 0

    init(providers: [AnyBitcoinNetworkProvider]) {
        self.providers = providers
    }

    var supportsTransactionPush: Bool { !providers.filter { $0.supportsTransactionPush }.isEmpty }

    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        providerPublisher {
            $0.getInfo(addresses: addresses)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        providerPublisher {
            $0.getInfo(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        Publishers.MergeMany(providers.map {
            $0.getFee()
                .retry(2)
                .catch { _ in
                    Empty()
                        .setFailureType(to: Error.self)
                }
                .eraseToAnyPublisher()
        })
        .collect()
        .tryMap { feeList -> BitcoinFee in
            let min: Decimal
            let norm: Decimal
            let priority: Decimal

            switch feeList.count {
            case 0:
                throw BlockchainSdkError.failedToLoadFee
            case 1:
                guard let feeItem = feeList.first else { throw BlockchainSdkError.failedToLoadFee }

                min = feeItem.minimalSatoshiPerByte
                norm = feeItem.normalSatoshiPerByte
                priority = feeItem.prioritySatoshiPerByte
            default:
                let divider = Decimal(feeList.count - 1)
                min = feeList.map { $0.minimalSatoshiPerByte }.sorted().dropFirst().reduce(0, +) / divider
                norm = feeList.map { $0.normalSatoshiPerByte }.sorted().dropFirst().reduce(0, +) / divider
                priority = feeList.map { $0.prioritySatoshiPerByte }.sorted().dropFirst().reduce(0, +) / divider
            }

            guard min >= 0, norm >= 0, priority >= 0 else {
                throw BlockchainSdkError.failedToLoadFee
            }
            return BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: norm, prioritySatoshiPerByte: priority)
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }

    func push(transaction: String) -> AnyPublisher<String, Error> {
        providers.first(where: { $0.supportsTransactionPush })?
            .push(transaction: transaction) ?? .anyFail(error: BlockchainSdkError.networkProvidersNotSupportsRbf)
    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getSignatureCount(address: address)
        }
    }
}
