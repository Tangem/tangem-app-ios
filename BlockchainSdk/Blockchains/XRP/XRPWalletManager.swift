//
//  XRPWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

enum XRPError: Int, Error, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    case failedLoadUnconfirmed
    case failedLoadReserve
    case failedLoadInfo
    case missingReserve
    case distinctTagsFound

    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    var errorDescription: String? {
        Localization.genericErrorCode("xrp_error \(rawValue)")
    }
}

class XRPWalletManager: BaseManager, WalletManager {
    var txBuilder: XRPTransactionBuilder!
    var networkService: XRPNetworkService!

    var currentHost: String { networkService.host }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(account: wallet.address)
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case .failure(let error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }

    private func updateWallet(with response: XrpInfoResponse) {
        wallet.add(reserveValue: response.reserve / Decimal(1000000))
        wallet.add(coinValue: (response.balance - response.reserve) / Decimal(1000000))

        txBuilder.account = wallet.address
        txBuilder.sequence = response.sequence
        if response.balance != response.unconfirmedBalance {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.clearPendingTransaction()
        }
    }

    private func decodeAddress(address: String) -> String {
        do {
            return try XRPAddress.decodeXAddress(xAddress: address).rAddress
        } catch {
            return address
        }
    }
}

extension XRPWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let addressDecoded = decodeAddress(address: transaction.destinationAddress)

        return networkService
            .checkAccountCreated(account: addressDecoded)
            .tryMap { [weak self] isAccountCreated -> (XRPTransaction, Data) in
                guard let self = self else { throw WalletError.empty }

                guard let walletReserve = wallet.amounts[.reserve],
                      let buldResponse = try txBuilder.buildForSign(transaction: transaction) else {
                    throw XRPError.missingReserve
                }

                if !isAccountCreated, transaction.amount.value < walletReserve.value {
                    throw WalletError.noAccount(message: Localization.sendErrorNoTargetAccount(walletReserve.value), amountToCreate: walletReserve.value)
                }

                return buldResponse
            }
            .flatMap { [weak self] buildResponse -> AnyPublisher<(XRPTransaction, Data), Error> in
                guard let self = self else { return .emptyFail }

                return signer.sign(
                    hash: buildResponse.1,
                    walletPublicKey: wallet.publicKey
                ).map {
                    return (buildResponse.0, $0)
                }.eraseToAnyPublisher()
            }
            .tryMap { [weak self] response -> (String) in
                guard let self = self else { throw WalletError.empty }

                return try txBuilder.buildForSend(transaction: response.0, signature: response.1)
            }
            .flatMap { [weak self] rawTransactionHash -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(blob: rawTransactionHash)
                    .tryMap { [weak self] hash in
                        guard let self = self else { throw WalletError.empty }

                        let mapper = PendingTransactionRecordMapper()
                        let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                        wallet.addPendingTransaction(record)
                        return TransactionSendResult(hash: hash)
                    }
                    .mapSendError(tx: rawTransactionHash)
                    .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .map { [weak self] xrpFeeResponse -> [Fee] in
                guard let self else { return [] }
                let blockchain = wallet.blockchain

                let min = xrpFeeResponse.min / blockchain.decimalValue
                let normal = xrpFeeResponse.normal / blockchain.decimalValue
                let max = xrpFeeResponse.max / blockchain.decimalValue

                let minFee = Amount(with: blockchain, value: min)
                let normalFee = Amount(with: blockchain, value: normal)
                let maxFee = Amount(with: blockchain, value: max)

                return [minFee, normalFee, maxFee].map { Fee($0) }
            }
            .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: ThenProcessable {}

extension XRPWalletManager: ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, addressType: ReserveAmountRestrictableAddressType) async throws {
        guard let walletReserve = wallet.amounts[.reserve] else {
            throw XRPError.missingReserve
        }

        let isAccountCreated: Bool = try await {
            switch addressType {
            case .notCreated:
                return false
            case .address(let address):
                let addressDecoded = decodeAddress(address: address)
                return try await networkService.checkAccountCreated(account: addressDecoded).async()
            }
        }()

        if !isAccountCreated, amount.value < walletReserve.value {
            throw ValidationError.reserve(amount: walletReserve)
        }
    }
}
