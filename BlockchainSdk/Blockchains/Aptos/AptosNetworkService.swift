//
//  AptosNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AptosNetworkService: MultiNetworkProvider {
    // MARK: - Protperties
    
    let providers: [AptosNetworkProvider]
    
    var currentProviderIndex: Int = 0
    
    // MARK: - Init
    
    init(providers: [AptosNetworkProvider]) {
        self.providers = providers
    }
    
    // MARK: - Implementation
    
    func getAccount(address: String) -> AnyPublisher<AptosAccountInfo, Error> {
        providerPublisher { provider in
            provider
                .getAccountResources(address: address)
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    guard
                        let accountJson = response.first(where: { $0.type == Constants.accountKeyPrefix }),
                        let coinJson = response.first(where: { $0.type == Constants.coinStoreKeyPrefix })
                    else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                    
                    guard
                        let balanceValue = Decimal(coinJson.data.coin?.value),
                        let sequenceNumber = Decimal(accountJson.data.sequenceNumber)
                    else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                    
                    return AptosAccountInfo(sequenceNumber: sequenceNumber.int64Value, balance: balanceValue)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasUnitPrice() -> AnyPublisher<UInt64, Error> {
        providerPublisher { provider in
            provider
                .getGasUnitPrice()
                .map { response in
                    response.gasEstimate
                }
                .eraseToAnyPublisher()
        }
    }

    func calculateUsedGasPriceUnit(info: AptosTransactionInfo) -> AnyPublisher<AptosFeeInfo, Error> {
        providerPublisher { [weak self] provider in
            guard let self = self else {
                return .anyFail(error: WalletError.failedToGetFee)
            }
            
            let transactionBody = convertTransaction(info: info)
            
            return provider
                .calculateUsedGasPriceUnit(transactionBody: transactionBody)
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    guard let gasUsed = Decimal(response.first?.gasUsed) else {
                        throw WalletError.failedToGetFee
                    }
                    
                    let maxGasAmount = gasUsed * Constants.successTransactionSafeFactor
                    let estimatedFeeDecimal = (Decimal(info.gasUnitPrice) * gasUsed * Constants.successTransactionSafeFactor)
                    
                    return AptosFeeInfo(
                        value: estimatedFeeDecimal,
                        params: AptosFeeParams(
                            gasUnitPrice: info.gasUnitPrice,
                            maxGasAmount: maxGasAmount.roundedDecimalNumber.uint64Value
                        )
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func submitTransaction(data: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            return provider
                .submitTransaction(data: data)
                .tryMap { response in
                    guard let transactionHash = response.hash else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                    
                    return transactionHash
                }
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private Implementation
    
    private func convertTransaction(info: AptosTransactionInfo) -> AptosRequest.TransactionBody {
        let transferPayload = AptosRequest.TransferPayload(
            type: Constants.transferPayloadType,
            function: Constants.transferPayloadFunction,
            typeArguments: [],
            arguments: [info.destinationAddress, String(info.amount)]
        )
        
        var signature: AptosRequest.Signature?
        
        if let hash = info.hash {
            signature = AptosRequest.Signature(
                type: Constants.signatureType,
                publicKey: info.publicKey,
                signature: hash
            )
        }
        
        return .init(
            sequenceNumber: String(info.sequenceNumber),
            sender: info.sourceAddress,
            gasUnitPrice: String(info.gasUnitPrice),
            maxGasAmount: String(info.maxGasAmount),
            expirationTimestampSecs: String(info.expirationTimestamp),
            payload: transferPayload,
            signature: signature
        )
    }
}

// MARK: - Constants

private extension AptosNetworkService {
    enum Constants {
        static let accountKeyPrefix = "0x1::account::Account"
        static let coinStoreKeyPrefix = "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
        static let transferPayloadType = "entry_function_payload"
        static let transferPayloadFunction = "0x1::aptos_account::transfer"
        static let aptosCoinContract = "0x1::aptos_coin::AptosCoin"
        static let signatureType = "ed25519_signature"
        static let successTransactionSafeFactor: Decimal = 1.5
    }
}
