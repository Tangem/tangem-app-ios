//
//  BitcoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BitcoinNetworkProvider: AnyObject, HostProvider {
    var supportsTransactionPush: Bool { get }
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error>
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error>
    func getFee() -> AnyPublisher<BitcoinFee, Error>
    func send(transaction: String) -> AnyPublisher<String, Error>
    func push(transaction: String) -> AnyPublisher<String, Error>
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error>
}

extension BitcoinNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: { [weak self] in
            self?.getInfo(address: $0) ?? .emptyFail
        })
    }

    func eraseToAnyBitcoinNetworkProvider() -> AnyBitcoinNetworkProvider {
        AnyBitcoinNetworkProvider(self)
    }
}

class AnyBitcoinNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { provider.supportsTransactionPush }
    var host: String { provider.host }

    private let provider: BitcoinNetworkProvider

    init<P: BitcoinNetworkProvider>(_ provider: P) {
        self.provider = provider
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        provider.getInfo(address: address)
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider.getFee()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        provider.send(transaction: transaction)
    }

    func push(transaction: String) -> AnyPublisher<String, Error> {
        provider.push(transaction: transaction)
    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        provider.getSignatureCount(address: address)
    }
}
