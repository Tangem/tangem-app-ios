//
//  TONNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TonSwift
import BigInt

/// Abstract layer for multi provide TON blockchain
class TONNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [TONProvider]
    var currentProviderIndex: Int = 0

    private var blockchain: Blockchain

    // MARK: - Init

    init(providers: [TONProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }

    // MARK: - Implementation

    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<TONWalletInfo, Error> {
        Publishers.Zip(
            getWalletInfo(address: address),
            getTokensInfo(address: address, tokens: tokens)
        )
        .tryMap { walletInfo, tokensInfo in
            guard let decimalBalance = Decimal(string: walletInfo.balance) else {
                throw WalletError.failedToParseNetworkResponse()
            }

            return TONWalletInfo(
                balance: decimalBalance / self.blockchain.decimalValue,
                sequenceNumber: walletInfo.seqno ?? 0,
                isAvailable: walletInfo.accountState == .active,
                tokensInfo: tokensInfo
            )
        }
        .eraseToAnyPublisher()
    }

    func getFee(address: String, message: String) -> AnyPublisher<[Fee], Error> {
        providerPublisher { provider in
            provider
                .getFee(address: address, body: message)
                .tryMap { [weak self] fee in
                    guard let self = self else {
                        throw WalletError.empty
                    }

                    /// Make rounded digits by correct for max amount Fee
                    let fee = fee.sourceFees.totalFee / blockchain.decimalValue
                    let roundedValue = fee.rounded(scale: 2, roundingMode: .up)
                    let feeAmount = Amount(with: blockchain, value: roundedValue)
                    return [Fee(feeAmount)]
                }
                .eraseToAnyPublisher()
        }
    }

    func getJettonWalletAddress(for ownerAddress: String, token: Token) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.getJettonWalletAddress(
                for: ownerAddress,
                contractAddress: token.contractAddress
            )
            .tryMap { response in
                let reader = TupleReader(items: response.stack)
                let address = try reader.readAddress()

                return address.toString(bounceable: false)
            }
            .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementation

    func send(message: String) -> AnyPublisher<String, Error> {
        return providerPublisher { provider in
            provider
                .send(message: message)
                .map(\.hash)
                .eraseToAnyPublisher()
        }
    }

    private func getWalletInfo(address: String) -> AnyPublisher<TONModels.Info, Error> {
        providerPublisher { provider in
            provider
                .getInfo(address: address)
        }
    }

    private func getTokensInfo(
        address: String,
        tokens: [Token]
    ) -> AnyPublisher<[Token: TONWalletInfo.TokenInfo], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, token in
                networkService.getTokenInfo(address: address, token: token).map { (token, $0) }
            }
            .collect()
            .map { $0.reduce(into: [Token: TONWalletInfo.TokenInfo]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }

    private func getTokenInfo(address: String, token: Token) -> AnyPublisher<TONWalletInfo.TokenInfo, Error> {
        providerPublisher { provider in
            provider.getJettonWalletAddress(
                for: address,
                contractAddress: token.contractAddress
            )
            .tryMap { response in
                let reader = TupleReader(
                    items: response.stack
                )
                let address = try reader.readAddress()

                return address.toString(bounceable: false)
            }
            .flatMap { jettonWalletAddress in
                provider.getJettonWalledData(jettonWalletAddress: jettonWalletAddress)
                    .tryMap { response in
                        let reader = TupleReader(
                            items: response.stack
                        )

                        let bigAmount = (try? reader.readBigNumber()) ?? 0

                        guard let decimalAmount = bigAmount.decimal else {
                            throw WalletError.failedToParseNetworkResponse(nil)
                        }

                        return TONWalletInfo.TokenInfo(
                            jettonWalletAddress: jettonWalletAddress,
                            balance: decimalAmount / token.decimalValue
                        )
                    }
            }.eraseToAnyPublisher()
        }
    }
}
