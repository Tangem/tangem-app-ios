//
//  KaspaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkService: MultiNetworkProvider {
    let providers: [KaspaNetworkProvider]
    var currentProviderIndex: Int = 0

    private let blockchain: Blockchain

    init(providers: [KaspaNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }

    func getInfo(address: String, unconfirmedTransactionHashes: [String]) -> AnyPublisher<KaspaAddressInfo, Error> {
        balance(address: address)
            .zip(getUnspentOutputs(address: address), confirmedTransactionHashes(unconfirmedTransactionHashes))
            .tryMap { [weak self] balance, unspentOutputs, confirmedTransactionHashes in
                guard let self else { throw WalletError.empty }

                return KaspaAddressInfo(
                    balance: Decimal(integerLiteral: balance.balance) / blockchain.decimalValue,
                    unspentOutputs: unspentOutputs,
                    confirmedTransactionHashes: confirmedTransactionHashes
                )
            }
            .eraseToAnyPublisher()
    }

    func getUnspentOutputs(address: String) -> AnyPublisher<[BitcoinUnspentOutput], Error> {
        providerPublisher {
            $0.utxos(address: address)
                .retry(2)
                .map { utxos in
                    return utxos.compactMap { utxo -> BitcoinUnspentOutput? in
                        guard
                            let amount = UInt64(utxo.utxoEntry.amount)
                        else {
                            return nil
                        }

                        return BitcoinUnspentOutput(
                            transactionHash: utxo.outpoint.transactionId,
                            outputIndex: utxo.outpoint.index,
                            amount: amount,
                            outputScript: utxo.utxoEntry.scriptPublicKey.scriptPublicKey
                        )
                    }
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: KaspaTransactionRequest, isReveal: Bool) -> AnyPublisher<KaspaTransactionResponse, Error> {
        return providerPublisher {
            $0.send(transaction: transaction)
        }
    }

    private func currentBlueScore() -> AnyPublisher<UInt64, Error> {
        providerPublisher {
            $0.currentBlueScore()
                .map(\.blueScore)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    private func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        providerPublisher {
            $0.balance(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    private func confirmedTransactionHashes(_ hashes: [String]) -> AnyPublisher<[String], Error> {
        if hashes.isEmpty {
            return .justWithError(output: [])
        }

        let confirmedTransactionBlueScoreDifference: UInt64 = 10

        return Publishers.Zip(currentBlueScore(), transactionInfos(hashes: hashes))
            .map { currentBlueScore, transactionInfos in
                let confirmedTransactions = transactionInfos.filter {
                    $0.isAccepted
                        &&
                        currentBlueScore > ($0.acceptingBlockBlueScore + confirmedTransactionBlueScoreDifference)
                }

                return confirmedTransactions.map(\.transactionId)
            }
            .eraseToAnyPublisher()
    }

    private func transactionInfos(hashes: [String]) -> AnyPublisher<[KaspaTransactionInfoResponse], Error> {
        hashes
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] hash -> AnyPublisher<KaspaTransactionInfoResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }

                return transactionInfo(hash: hash)
                    .replaceError(with: .init(transactionId: hash, isAccepted: false, acceptingBlockBlueScore: 0))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
    }

    private func transactionInfo(hash: String) -> AnyPublisher<KaspaTransactionInfoResponse, Error> {
        providerPublisher {
            $0.transactionInfo(hash: hash)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    func mass(data: KaspaTransactionData) -> AnyPublisher<KaspaMassResponse, Error> {
        providerPublisher { provider in
            provider.mass(data: data)
        }
    }

    func feeEstimate() -> AnyPublisher<KaspaFeeEstimateResponse, Error> {
        providerPublisher { provider in
            provider.feeEstimate()
        }
    }
}
