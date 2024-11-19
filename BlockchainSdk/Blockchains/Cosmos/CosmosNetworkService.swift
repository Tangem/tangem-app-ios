//
//  CosmosNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CosmosNetworkService: MultiNetworkProvider {
    let providers: [CosmosRestProvider]
    var currentProviderIndex: Int = 0

    private let cosmosChain: CosmosChain

    init(cosmosChain: CosmosChain, providers: [CosmosRestProvider]) {
        self.providers = providers
        self.cosmosChain = cosmosChain
    }

    func accountInfo(for address: String, tokens: [Token], transactionHashes: [String]) -> AnyPublisher<CosmosAccountInfo, Error> {
        let cw20Tokens: [Token]
        if cosmosChain.allowCW20Tokens {
            cw20Tokens = tokens
        } else {
            cw20Tokens = []
        }

        return providerPublisher {
            $0.accounts(address: address)
                .zip($0.balances(address: address), self.cw20TokenBalances(walletAddress: address, tokens: cw20Tokens), self.confirmedTransactionHashes(transactionHashes, with: $0))
                .tryMap { [weak self] accountInfo, balanceInfo, cw20TokenBalances, confirmedTransactionHashes in
                    guard
                        let self,
                        let sequenceNumber = UInt64(accountInfo?.account.sequence ?? "0")
                    else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    let accountNumber: UInt64?
                    if let account = accountInfo?.account {
                        accountNumber = UInt64(account.accountNumber)
                    } else {
                        accountNumber = nil
                    }

                    let rawAmount = try parseBalance(
                        balanceInfo,
                        denomination: cosmosChain.smallestDenomination,
                        decimalValue: cosmosChain.blockchain.decimalValue
                    )
                    let amount = Amount(with: cosmosChain.blockchain, value: rawAmount)

                    let tokenAmounts: [Token: Decimal]
                    if cosmosChain.allowCW20Tokens {
                        tokenAmounts = cw20TokenBalances
                    } else {
                        tokenAmounts = Dictionary(try tokens.compactMap {
                            guard let denomination = self.cosmosChain.tokenDenomination(contractAddress: $0.contractAddress, tokenCurrencySymbol: $0.symbol) else {
                                return nil
                            }

                            let balance = try self.parseBalance(balanceInfo, denomination: denomination, decimalValue: $0.decimalValue)
                            return ($0, balance)
                        }, uniquingKeysWith: {
                            pair1, _ in
                            pair1
                        })
                    }

                    return CosmosAccountInfo(
                        accountNumber: accountNumber,
                        sequenceNumber: sequenceNumber,
                        amount: amount,
                        tokenBalances: tokenAmounts,
                        confirmedTransactionHashes: confirmedTransactionHashes
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func estimateGas(for transaction: Data) -> AnyPublisher<UInt64, Error> {
        providerPublisher {
            $0.simulate(data: transaction)
                .map(\.gasInfo.gasUsed)
                .tryMap {
                    guard let gasUsed = UInt64($0) else {
                        throw WalletError.failedToGetFee
                    }

                    return gasUsed
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.txs(data: transaction)
                .map(\.txResponse)
                .tryMap { txResponse in
                    guard txResponse.code == 0 else {
                        throw WalletError.failedToSendTx
                    }

                    return txResponse.txhash
                }
                .eraseToAnyPublisher()
        }
    }

    private func cw20TokenBalances(walletAddress: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] token -> AnyPublisher<(Token, Decimal), Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }

                return cw20TokenBalance(walletAddress: walletAddress, token: token)
            }
            .collect()
            .map {
                Dictionary($0) { pair1, _ in pair1 }
            }
            .eraseToAnyPublisher()
    }

    private func cw20TokenBalance(walletAddress: String, token: Token) -> AnyPublisher<(Token, Decimal), Error> {
        let request = CosmosCW20BalanceRequest(address: walletAddress)
        guard let query = try? JSONEncoder().encode(request) else {
            return .anyFail(error: WalletError.failedToParseNetworkResponse())
        }

        return providerPublisher {
            $0.querySmartContract(contractAddress: token.contractAddress, query: query)
                .tryMap {
                    (result: CosmosCW20QueryResult<CosmosCW20QueryBalanceData>) -> (Token, Decimal) in

                    guard let balanceInSmallestDenomination = Decimal(string: result.data.balance) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }

                    let balance = balanceInSmallestDenomination / token.decimalValue
                    return (token, balance)
                }
                .eraseToAnyPublisher()
        }
    }

    private func confirmedTransactionHashes(_ hashes: [String], with provider: CosmosRestProvider) -> AnyPublisher<[String], Error> {
        hashes
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] hash -> AnyPublisher<String?, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                return transactionConfirmed(hash, with: provider)
            }
            .collect()
            .map {
                $0.compactMap { $0 }
            }
            .eraseToAnyPublisher()
    }

    private func transactionConfirmed(_ hash: String, with provider: CosmosRestProvider) -> AnyPublisher<String?, Error> {
        provider.transactionStatus(hash: hash)
            .map(\.txResponse)
            .compactMap { response in
                if let height = UInt64(response.height),
                   height > 0 {
                    return hash
                } else {
                    return nil
                }
            }
            .tryCatch { error -> AnyPublisher<String?, Error> in
                if case WalletError.failedToParseNetworkResponse = error {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }

    private func parseBalance(_ balanceInfo: CosmosBalanceResponse, denomination: String, decimalValue: Decimal) throws -> Decimal {
        guard let balanceAmountString = balanceInfo.balances.first(where: { $0.denom == denomination })?.amount else {
            return .zero
        }

        guard let balanceInSmallestDenomination = Int(balanceAmountString) else {
            throw WalletError.failedToParseNetworkResponse()
        }

        return Decimal(balanceInSmallestDenomination) / decimalValue
    }
}
