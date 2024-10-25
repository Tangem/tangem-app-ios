//
//  SolanaSdk+.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 21.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SolanaSwift

extension Api {
    func getFees(
        commitment: Commitment? = nil
    ) -> AnyPublisher<SolanaSwift.Fee, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getFees(commitment: commitment) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getFeeForMessage(_ message: String) -> AnyPublisher<FeeForMessageResult, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getFeeForMessage(message: message) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let feeForMessage):
                        promise(.success(feeForMessage))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getMinimumBalanceForRentExemption(
        dataLength: UInt64,
        commitment: Commitment? = nil
    ) -> AnyPublisher<UInt64, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getMinimumBalanceForRentExemption(
                    dataLength: dataLength,
                    commitment: commitment
                ) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getAccountInfo<T: BufferLayout>(account: String, decodedTo: T.Type) -> AnyPublisher<BufferInfo<T>, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getAccountInfo(account: account, decodedTo: T.self) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getTokenAccountsByOwner<T: Decodable>(
        pubkey: String,
        mint: String? = nil,
        programId: String? = nil,
        configs: RequestConfiguration? = nil
    ) -> AnyPublisher<[T], Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getTokenAccountsByOwner(pubkey: pubkey, mint: mint, programId: programId, configs: configs) {
                    (result: Result<[T], Error>) in

                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let accounts):
                        promise(.success(accounts))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getSignatureStatuses(pubkeys: [String], configs: RequestConfiguration? = nil) -> AnyPublisher<[SignatureStatus?], Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getSignatureStatuses(pubkeys: pubkeys, configs: configs) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let statuses):
                        promise(.success(statuses))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendTransaction(
        serializedTransaction: String,
        configs: RequestConfiguration = RequestConfiguration(encoding: "base64", maxRetries: 12)!
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                sendTransaction(serializedTransaction: serializedTransaction, configs: configs, startSendingTimestamp: Date()) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let statuses):
                        promise(.success(statuses))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension Action {
    func serializeMessage(
        to destination: String,
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        allowUnfundedRecipient: Bool = false,
        fromPublicKey: PublicKey
    ) -> AnyPublisher<(String, Date), Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                serializeMessage(
                    to: destination,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    fromPublicKey: fromPublicKey
                ) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let message):
                        promise(.success(message))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendSOL(
        to destination: String,
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        allowUnfundedRecipient: Bool = false,
        signer: Signer
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                sendSOL(
                    to: destination,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    signer: signer
                ) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let transactionID):
                        promise(.success(transactionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendSPLTokens(
        mintAddress: String,
        tokenProgramId: PublicKey,
        decimals: Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        allowUnfundedRecipient: Bool = false,
        signer: Signer
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                sendSPLTokens(
                    mintAddress: mintAddress,
                    tokenProgramId: tokenProgramId,
                    decimals: decimals,
                    from: fromPublicKey,
                    to: destinationAddress,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    signer: signer
                ) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let transactionID):
                        promise(.success(transactionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension NetworkingRouter: HostProvider {
    var host: String {
        endpoint.url.hostOrUnknown
    }
}
