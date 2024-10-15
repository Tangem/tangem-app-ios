//
//  StellarNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine

@available(iOS 13.0, *)
class StellarNetworkProvider: HostProvider {
    let isTestnet: Bool
    let stellarSdk: StellarSDK
    
    var host: String {
        URL(string: stellarSdk.horizonURL)!.hostOrUnknown
    }
    
    private var blockchain: Blockchain {
        Blockchain.stellar(curve: .ed25519_slip0010, testnet: isTestnet)
    }
    
    init(isTestnet: Bool, stellarSdk: StellarSDK) {
        self.isTestnet = isTestnet
        self.stellarSdk = stellarSdk
    }
    
    public func checkTargetAccount(address: String, token: Token?) -> AnyPublisher<StellarTargetAccountResponse, Error> {
        stellarSdk.accounts.checkTargetAccount(address: address, token: token)
    }
    
    public func send(transaction: String) -> AnyPublisher<String, Error> {
        return stellarSdk.transactions.postTransaction(transactionEnvelope: transaction)
            .tryMap{ submitTransactionResponse throws  -> String in
                if submitTransactionResponse.transactionResult.code == .success {
                    return submitTransactionResponse.transactionHash
                } else {
                    throw "Result code: \(submitTransactionResponse.transactionResult.code)"
                }
            }
            .mapError {[weak self] in self?.mapError($0) ?? WalletError.empty }
            .eraseToAnyPublisher()
    }
    
    public func getInfo(accountId: String, isAsset: Bool) -> AnyPublisher<StellarResponse, Error> {
        return stellarData(accountId: accountId)
            .tryMap{ [weak self] (accountResponse, ledgerResponse) throws -> StellarResponse in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let baseReserveStroops = Decimal(ledgerResponse.baseReserveInStroops)
                guard let balance = Decimal(accountResponse.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE})?.balance) else {
                    throw WalletError.failedToParseNetworkResponse()
                }
                
                let sequence = accountResponse.sequenceNumber
                let assetBalances = try accountResponse.balances
                    .filter ({ $0.assetType != AssetTypeAsString.NATIVE })
                    .map { assetBalance -> StellarAssetResponse in
                        guard let code = assetBalance.assetCode,
                              let issuer = assetBalance.assetIssuer,
                              let balance = Decimal(assetBalance.balance) else {
                            throw WalletError.failedToParseNetworkResponse()
                        }
                        
                        return StellarAssetResponse(code: code, issuer: issuer, balance: balance)
                    }
                
                let divider = self.blockchain.decimalValue
                let baseReserve = baseReserveStroops/divider
                
                return StellarResponse(baseReserve: baseReserve,
                                       assetBalances: assetBalances,
                                       balance: balance,
                                       sequence: sequence)
            }
            .mapError {[weak self] in self?.mapError($0, isAsset: isAsset) ?? WalletError.empty }
            .eraseToAnyPublisher()
    }
    
    public func getFee() -> AnyPublisher<[Amount], Error> {
        stellarSdk.feeStats.getFeeStats()
            .tryMap { [blockchain] feeStats -> [Amount] in
                guard let feeChargedModeInStroops = Decimal(feeStats.feeCharged.mode),
                      let feeChargedP80InStroops = Decimal(feeStats.feeCharged.p80),
                      let feeChargedP99InStroops = Decimal(feeStats.feeCharged.p99)
                else {
                    throw WalletError.failedToGetFee
                }
                
                let divider =  blockchain.decimalValue
                
                let feeChargedMode = feeChargedModeInStroops / divider
                let feeChargedP80 = feeChargedP80InStroops / divider
                let feeChargedP99 = feeChargedP99InStroops / divider
                
                let fees = [
                    feeChargedMode,
                    feeChargedP80,
                    feeChargedP99,
                ].map {
                    Amount(with: blockchain, value: $0)
                }
                
                return fees
            }
            .eraseToAnyPublisher()
    }
    
    private func stellarData(accountId: String) -> AnyPublisher<(AccountResponse, LedgerResponse), Error> {
        Publishers.Zip(stellarSdk.accounts.getAccountDetails(accountId: accountId),
                       stellarSdk.ledgers.getLatestLedger())
        .eraseToAnyPublisher()
    }
    
    private func mapError(_ error: Error, isAsset: Bool? = nil) -> Error {
        if let horizonError = error as? HorizonRequestError {
            if case .notFound = horizonError, let isAsset = isAsset {
                if isAsset {
                    return WalletError.noAccount(
                        message: StellarError.assetCreateAccount.localizedDescription,
                        amountToCreate: StellarWalletManager.Constants.minAmountToCreateAssetAccount
                    )
                }
                
                return WalletError.noAccount(
                    message: StellarError.xlmCreateAccount.localizedDescription,
                    amountToCreate: StellarWalletManager.Constants.minAmountToCreateCoinAccount
                )
            } else {
                return horizonError.parseError()
            }
        } else {
            return error
        }
    }
}

extension StellarNetworkProvider {
    public func getSignatureCount(accountId: String) -> AnyPublisher<Int, Error> {
        stellarSdk.operations.getAllOperations(accountId: accountId, recordsLimit: 1)
            .map { items in
                items.filter { $0.sourceAccount == accountId }.count
            }
            .mapError {[weak self] in self?.mapError($0) ?? WalletError.empty }
            .eraseToAnyPublisher()
    }
}


struct StellarResponse {
    let baseReserve: Decimal
    let assetBalances: [StellarAssetResponse]
    let balance: Decimal
    let sequence: Int64
}

struct StellarAssetResponse {
    let code: String
    let issuer: String
    let balance: Decimal
}

struct StellarTargetAccountResponse {
    let accountCreated: Bool
    let trustlineCreated: Bool
}
