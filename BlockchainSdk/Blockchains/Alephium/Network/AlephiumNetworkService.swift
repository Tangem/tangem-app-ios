//
//  AlephiumNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AlephiumNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [AlephiumNetworkProvider]
    var currentProviderIndex: Int = 0

    // MARK: - Init

    init(providers: [AlephiumNetworkProvider]) {
        self.providers = providers
    }

    // MARK: - Implementation

    func getAccountInfo(for address: String) -> AnyPublisher<AlephiumAccountInfo, Error> {
        Publishers.Zip(
            getBalance(address: address),
            getUTXO(address: address)
        )
        .tryMap { args in
            let (balance, utxo) = args
            return AlephiumAccountInfo(balance: balance, utxo: utxo)
        }
        .eraseToAnyPublisher()
    }

    func getFee(
        from publicKey: String,
        destination: String,
        amount: String
    ) -> AnyPublisher<[Fee], Error> {
        let destination = AlephiumNetworkRequest.Destination(
            address: destination,
            attoAlphAmount: amount
        )

        let transfer = AlephiumNetworkRequest.BuildTransferTx(
            fromPublicKey: publicKey,
            destinations: [destination]
        )

        return providerPublisher { provider in
            provider
                .buildTransaction(transfer: transfer)
                .tryMap { response in
                    throw WalletError.failedToBuildTx
                }
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementations

    private func getBalance(address: String) -> AnyPublisher<AlephiumBalanceInfo, Error> {
        providerPublisher { provider in
            provider
                .getBalance(address: address)
                .tryMap {
                    guard
                        let balance = Decimal(stringValue: $0.balance),
                        let lockedBalance = Decimal(stringValue: $0.lockedBalance)
                    else {
                        throw WalletError.empty
                    }

                    return AlephiumBalanceInfo(value: balance, lockedValue: lockedBalance)
                }
                .eraseToAnyPublisher()
        }
    }

    private func getUTXO(address: String) -> AnyPublisher<[AlephiumUTXO], Error> {
        providerPublisher { provider in
            provider
                .getUTXOs(address: address)
                .map { utxos in
                    []
                }
                .eraseToAnyPublisher()
        }
    }
}
