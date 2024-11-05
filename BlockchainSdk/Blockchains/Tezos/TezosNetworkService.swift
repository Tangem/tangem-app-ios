//
//  TezosNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 19.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class TezosNetworkService: MultiNetworkProvider {
    let providers: [TezosJsonRpcProvider]
    var currentProviderIndex: Int = 0

    init(providers: [TezosJsonRpcProvider]) {
        self.providers = providers
    }

    func getInfo(address: String) -> AnyPublisher<TezosAddress, Error> {
        providerPublisher {
            Publishers.Zip(
                $0.getInfo(address: address),
                $0.checkPublicKeyRevealed(address: address)
            )
            .tryMap { tezosAddress, isPublicKeyRevealed -> TezosAddress in
                guard let balanceString = tezosAddress.balance,
                      let balance = Decimal(string: balanceString),
                      let counterString = tezosAddress.counter,
                      let counter = Int(counterString) else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                let balanceConverted = balance / Blockchain.tezos(curve: .ed25519).decimalValue
                return TezosAddress(balance: balanceConverted, counter: counter, isPublicKeyRevealed: isPublicKeyRevealed)
            }
            .eraseToAnyPublisher()
        }
    }

    func checkPublicKeyRevealed(address: String) -> AnyPublisher<Bool, Error> {
        providerPublisher {
            $0.checkPublicKeyRevealed(address: address)
                .eraseToAnyPublisher()
        }
    }

    func getHeader() -> AnyPublisher<TezosHeader, Error> {
        providerPublisher {
            $0.getHeader()
                .tryMap { headerResponse -> TezosHeader in
                    guard let proto = headerResponse.protocol, let hash = headerResponse.hash else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    return TezosHeader(protocol: proto, hash: hash)
                }
                .eraseToAnyPublisher()
        }
    }

    func forgeContents(headerHash: String, contents: [TezosOperationContent]) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.forgeContents(headerHash: headerHash, contents: contents)
                .eraseToAnyPublisher()
        }
    }

    func checkTransaction(
        protocol: String,
        hash: String,
        contents: [TezosOperationContent],
        signature: String
    ) -> AnyPublisher<Response, Error> {
        providerPublisher {
            $0.checkTransaction(
                protocol: `protocol`,
                hash: hash,
                contents: contents,
                signature: signature
            )
            .eraseToAnyPublisher()
        }
    }

    func sendTransaction(_ transaction: String) -> AnyPublisher<Response, Error> {
        providerPublisher { $0.sendTransaction(transaction).eraseToAnyPublisher() }
    }
}
