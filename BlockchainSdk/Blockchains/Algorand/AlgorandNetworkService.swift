//
//  AlgorandNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AlgorandNetworkService: MultiNetworkProvider {
    // MARK: - Protperties
    
    let blockchain: Blockchain
    let providers: [AlgorandNetworkProvider]
    var currentProviderIndex: Int = 0
    
    // MARK: - Init
    
    init(blockchain: Blockchain, providers: [AlgorandNetworkProvider]) {
        self.blockchain = blockchain
        self.providers = providers
    }
    
    // MARK: - Implementation
    
    func getAccount(address: String) -> AnyPublisher<AlgorandAccountModel, Error> {
        providerPublisher { provider in
            provider
                .getAccount(address: address)
                .withWeakCaptureOf(self)
                .map { service, response in
                    let accountModel = service.calculateCoinValueWithReserveDeposit(from: response)
                    return accountModel
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getEstimatedFee() -> AnyPublisher<AlgorandEstimatedFeeParams, Error> {
        providerPublisher { provider in
            provider
                .getTransactionParams()
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    let sourceFee = Decimal(response.fee) / service.blockchain.decimalValue
                    let minFee = Decimal(response.minFee) / service.blockchain.decimalValue
                    
                    return AlgorandEstimatedFeeParams(
                        minFee: Amount(with: service.blockchain, value: minFee),
                        fee: Amount(with: service.blockchain, value: sourceFee)
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getTransactionParams() -> AnyPublisher<AlgorandTransactionBuildParams, Error> {
        providerPublisher { provider in
            provider
                .getTransactionParams()
                .tryMap { response in
                    /// This paramenter mast be writen for building transaction
                    guard let genesisHash = Data(base64Encoded: response.genesisHash) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                    
                    let transactionParams = AlgorandTransactionBuildParams(
                        genesisId: response.genesisId,
                        genesisHash: genesisHash,
                        firstRound: response.lastRound,
                        lastRound: response.lastRound + Constants.bounceRoundValue
                    )
                    
                    return transactionParams
                }
                .eraseToAnyPublisher()
        }
    }
    
    func sendTransaction(data: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider
                .sendTransaction(data: data)
                .map { response in
                    return response.txId
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getPendingTransaction(transactionHash: String) -> AnyPublisher<AlgorandTransactionInfo?, Error> {
        return providerPublisher { provider in
            return provider
                .getPendingTransaction(txId: transactionHash)
                .catch { error in
                    // Need for use non blocked any requests due to the fact that this request throws 404 after some time for trnsaction id
                    Just(nil)
                }
                .tryMap { response in
                    guard let response = response, let confirmedRound = response.confirmedRound else {
                        return nil
                    }
                    
                    if confirmedRound > 0 {
                        return AlgorandTransactionInfo(transactionHash: transactionHash, status: .committed)
                    } else if confirmedRound == 0, response.poolError.isEmpty {
                        return AlgorandTransactionInfo(transactionHash: transactionHash, status: .still)
                    } else if confirmedRound == 0, !response.poolError.isEmpty {
                        return AlgorandTransactionInfo(transactionHash: transactionHash, status: .removed)
                    } else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Private Implementation

private extension AlgorandNetworkService {
    func calculateCoinValueWithReserveDeposit(from accountModel: AlgorandResponse.Account) -> AlgorandAccountModel {
        let changeBalanceValue = max(Decimal(accountModel.amount) - Decimal(accountModel.minBalance), 0)
        
        let decimalCoinValue = Decimal(accountModel.amount) / blockchain.decimalValue
        let decimalReserveValue = Decimal(accountModel.minBalance) / blockchain.decimalValue
        let decimalCoinWithReserveValue = changeBalanceValue / blockchain.decimalValue
        
        return AlgorandAccountModel(
            reserveValue: decimalReserveValue,
            coinValue: decimalCoinValue,
            coinValueWithReserveValue: decimalCoinWithReserveValue
        )
    }
}

// MARK: - Constants

private extension AlgorandNetworkService {
    enum Constants {
        /*
         https://developer.algorand.org/docs/get-details/transactions/
         This parameter descripe transaction is valid if submitted between rounds. Look at this doc.
         */
        static let bounceRoundValue: UInt64 = 1000
    }
}
