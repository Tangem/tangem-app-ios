//
//  AdaliteNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemNetworkUtils

class AdaliteNetworkProvider: CardanoNetworkProvider {
    private let url: URL
    private let provider: NetworkProvider<AdaliteTarget>
    private let cardanoResponseMapper: CardanoResponseMapper

    var host: String {
        url.hostOrUnknown
    }

    init(
        url: URL,
        configuration: NetworkProviderConfiguration,
        cardanoResponseMapper: CardanoResponseMapper
    ) {
        self.url = url
        provider = NetworkProvider<AdaliteTarget>(configuration: configuration)
        self.cardanoResponseMapper = cardanoResponseMapper
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(request(for: .send(base64EncodedTx: transaction.base64EncodedString())))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
            .map { hash in
                // Remove \" from the string
                // Because in response the hash is equal `"239392bc6c6bd354d5a95b77f799b61ac056c65566a10bb50033a7c9deabfe42"`
                hash.replacingOccurrences(of: "\"", with: "")
            }
            .eraseToAnyPublisher()
    }

    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        Publishers
            .Zip(getUnspents(addresses: addresses), getBalance(addresses: addresses))
            .tryMap { [weak self] unspents, responses -> CardanoAddressResponse in
                guard let self = self else {
                    throw WalletError.empty
                }

                let txHashes = responses.flatMap { $0.transactions }
                return cardanoResponseMapper.mapToCardanoAddressResponse(
                    tokens: tokens,
                    unspentOutputs: unspents,
                    recentTransactionsHashes: txHashes
                )
            }
            .retry(2)
            .eraseToAnyPublisher()
    }

    private func getUnspents(addresses: [String]) -> AnyPublisher<[CardanoUnspentOutput], Error> {
        provider
            .requestPublisher(request(for: .unspents(addresses: addresses)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(AdaliteBaseResponseDTO<String, [AdaliteUnspentOutputResponseDTO]>.self)
            .tryMap { [weak self] response throws -> [CardanoUnspentOutput] in
                guard let self, let unspentOutputs = response.right else {
                    throw response.left ?? WalletError.empty
                }

                return unspentOutputs.compactMap { self.mapToCardanoUnspentOutput($0) }
            }
            .eraseToAnyPublisher()
    }

    private func getBalance(addresses: [String]) -> AnyPublisher<[AdaliteBalanceResponse], Error> {
        .multiAddressPublisher(addresses: addresses) { [weak self] in
            guard let self = self else { return .emptyFail }

            return provider
                .requestPublisher(request(for: .address(address: $0)))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(AdaliteBaseResponseDTO<String, AdaliteBalanceResponseDTO>.self)
                .tryMap { [weak self] response throws -> AdaliteBalanceResponse in
                    guard let self, let balanceResponse = response.right else {
                        throw response.left ?? WalletError.empty
                    }

                    return self.mapToAdaliteBalanceResponse(balanceResponse)
                }
                .eraseToAnyPublisher()
        }
    }

    private func request(for target: AdaliteTarget.AdaliteTargetType) -> AdaliteTarget {
        return .init(baseURL: url, target: target)
    }
}

// MARK: - Mapping

private extension AdaliteNetworkProvider {
    func mapToAdaliteBalanceResponse(_ balanceResponse: AdaliteBalanceResponseDTO) -> AdaliteBalanceResponse {
        let transactions = balanceResponse.caTxList.map { $0.ctbId }
        return AdaliteBalanceResponse(transactions: transactions)
    }

    func mapToCardanoUnspentOutput(_ output: AdaliteUnspentOutputResponseDTO) -> CardanoUnspentOutput? {
        guard let amount = UInt64(output.cuCoins.getCoin) else {
            return nil
        }

        let assets: [CardanoUnspentOutput.Asset] = output.cuCoins.getTokens.compactMap { token in
            guard let amount = UInt64(token.quantity) else {
                return nil
            }

            return CardanoUnspentOutput.Asset(policyID: token.policyId, assetNameHex: token.assetName, amount: amount)
        }

        return CardanoUnspentOutput(
            address: output.cuAddress,
            amount: amount,
            outputIndex: output.cuOutIndex,
            transactionHash: output.cuId,
            assets: assets
        )
    }
}
