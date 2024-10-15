//
//  TronNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

class TronNetworkService: MultiNetworkProvider {
    let providers: [TronJsonRpcProvider]
    var currentProviderIndex: Int = 0
    
    let isTestnet: Bool
    
    private var blockchain: Blockchain {
        Blockchain.tron(testnet: isTestnet)
    }
    
    init(isTestnet: Bool, providers: [TronJsonRpcProvider]) {
        self.isTestnet = isTestnet
        self.providers = providers
    }
    
    func chainParameters() -> AnyPublisher<TronChainParameters, Error> {
        providerPublisher {
            $0.getChainParameters()
                .tryMap {
                    guard
                        let energyFeeChainParameter = $0.chainParameter.first(where: { $0.key == "getEnergyFee" }),
                        let energyFee = energyFeeChainParameter.value,
                        let dynamicEnergyMaxFactorChainParameter = $0.chainParameter.first(where: { $0.key == "getDynamicEnergyMaxFactor" }),
                        let dynamicEnergyMaxFactor = dynamicEnergyMaxFactorChainParameter.value,
                        let dynamicEnergyIncreaseFactorParameter = $0.chainParameter.first(where: { $0.key == "getDynamicEnergyIncreaseFactor" }),
                        let dynamicEnergyIncreaseFactor = dynamicEnergyIncreaseFactorParameter.value
                    else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                    
                    return TronChainParameters(
                        sunPerEnergyUnit: energyFee,
                        dynamicEnergyMaxFactor: dynamicEnergyMaxFactor,
                        dynamicEnergyIncreaseFactor: dynamicEnergyIncreaseFactor
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func accountInfo(for address: String, tokens: [Token], transactionIDs: [String]) -> AnyPublisher<TronAccountInfo, Error> {
        Publishers.Zip3(
            getAccount(for: address),
            tokenBalances(address: address, tokens: tokens),
            confirmedTransactionIDs(ids: transactionIDs)
        )
        .map { [blockchain] (accountInfo, tokenBalances, confirmedTransactionIDs) in
            let balance = Decimal(accountInfo.balance ?? 0) / blockchain.decimalValue
            return TronAccountInfo(
                balance: balance,
                tokenBalances: tokenBalances,
                confirmedTransactionIDs: confirmedTransactionIDs
            )
        }
        .eraseToAnyPublisher()
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        providerPublisher {
            $0.getNowBlock()
        }
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        providerPublisher {
            $0.broadcastHex(data)
        }
    }
    
    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        providerPublisher {
            $0.getAccountResource(for: address)
                .mapError { error in
                    if case let WalletError.failedToParseNetworkResponse(response) = error,
                       let data = response?.data,
                       let string = String(data: data, encoding: .utf8),
                       string.trimmingCharacters(in: .whitespacesAndNewlines) == "{}"
                    {
                        return WalletError.accountNotActivated
                    }
                    return error
                }
                .eraseToAnyPublisher()
        }
    }
    
    func accountExists(address: String) -> AnyPublisher<Bool, Error> {
        providerPublisher {
            $0.getAccount(for: address)
                .map { _ in
                    true
                }
                .tryCatch { error -> AnyPublisher<Bool, Error> in
                    if case WalletError.failedToParseNetworkResponse = error {
                        return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }
    
    func contractEnergyUsage(sourceAddress: String, contractAddress: String, contractEnergyUsageData: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.contractEnergyUsage(sourceAddress: sourceAddress, contractAddress: contractAddress, parameter: contractEnergyUsageData)
                .map(\.energy_used)
                .eraseToAnyPublisher()
        }
    }

    func getAllowance(owner: String, contractAddress: String, allowanceData: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher {
            $0.getAllowance(sourceAddress: owner, contractAddress: contractAddress, parameter: allowanceData)
                .tryMap { response in
                    // TODO: Use EthereumUtils instead?
                    try TronUtils().parseBalance(
                        response: response.constant_result,
                        decimals: 0
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementation
    
    private func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        providerPublisher {
            $0.getAccount(for: address)
                .tryCatch { error -> AnyPublisher<TronGetAccountResponse, Error> in
                    if case WalletError.failedToParseNetworkResponse = error {
                        return Just(TronGetAccountResponse(balance: 0, address: address))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }

    private func tokenBalances(address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        Result {
            try TronUtils().convertAddressToBytesPadded(address).hexString.lowercased()
        }
        .publisher
        .flatMap { encodedAddressData in
            tokens
                .publisher
                .setFailureType(to: Error.self)
                .map { (encodedAddressData, $0) }
        }
        .withWeakCaptureOf(self)
        .flatMap { args -> AnyPublisher<(Token, Decimal), Error> in
            let (service, (encodedAddressData, token)) = args

            return service
                .tokenBalance(address: address, token: token, encodedAddressData: encodedAddressData)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .collect()
        .map {
            $0.reduce(into: [:]) { tokenBalances, tokenBalance in
                tokenBalances[tokenBalance.0] = tokenBalance.1
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func tokenBalance(address: String, token: Token, encodedAddressData: String) -> AnyPublisher<(Token, Decimal), Never> {
        providerPublisher {
            $0.tokenBalance(address: address, contractAddress: token.contractAddress, parameter: encodedAddressData)
                .tryMap { response in
                    let value = try TronUtils().parseBalance(
                        response: response.constant_result,
                        decimals: token.decimalCount
                    )
                    return (token, value)
                }
                .eraseToAnyPublisher()
        }
        .replaceError(with: (token, .zero))
        .eraseToAnyPublisher()
    }
    
    private func confirmedTransactionIDs(ids transactionIDs: [String]) -> AnyPublisher<[String], Error> {
        transactionIDs
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] transactionID -> AnyPublisher<String?, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                return self.transactionConfirmed(id: transactionID)
            }
            .collect()
            .map {
                $0.reduce(into: []) { confirmedTransactionIDs, confirmedTransactionID in
                    if let confirmedTransactionID = confirmedTransactionID {
                        confirmedTransactionIDs.append(confirmedTransactionID)
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func transactionConfirmed(id: String) -> AnyPublisher<String?, Error> {
        providerPublisher {
            $0.transactionInfo(id: id)
                .map { _ in
                    return id
                }
                .tryCatch { error -> AnyPublisher<String?, Error> in
                    if case WalletError.failedToParseNetworkResponse = error {
                        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }
}
