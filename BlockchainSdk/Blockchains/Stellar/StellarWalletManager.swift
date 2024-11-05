//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import SwiftyJSON
import Combine
import TangemSdk

enum StellarError: Int, Error, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    case emptyResponse
    case requiresMemo
    case failedToFindLatestLedger
    case xlmCreateAccount
    case assetCreateAccount
    case assetNoAccountOnDestination
    case assetNoTrustline

    // WARNING: Make sure to preserve the error codes when removing or inserting errors

    var errorDescription: String? {
        let networkName = Blockchain.stellar(curve: .ed25519, testnet: false).displayName
        switch self {
        case .requiresMemo:
            return Localization.xlmRequiresMemoError
        case .xlmCreateAccount:
            return Localization.noAccountGeneric(networkName, "\(StellarWalletManager.Constants.minAmountToCreateCoinAccount)", "XLM")
        case .assetCreateAccount:
            return Localization.noAccountGeneric(networkName, "\(StellarWalletManager.Constants.minAmountToCreateAssetAccount)", "XLM")
        case .assetNoAccountOnDestination:
            return Localization.sendErrorNoTargetAccount("\(StellarWalletManager.Constants.minAmountToCreateCoinAccount) XLM")
        case .assetNoTrustline:
            return Localization.noTrustlineXlmAsset
        default:
            return Localization.genericErrorCode(errorCodeDescription)
        }
    }

    private var errorCodeDescription: String {
        "stellar_error \(rawValue)"
    }
}

extension StellarWalletManager {
    enum Constants {
        /// 1 XLM
        static let minAmountToCreateCoinAccount: Decimal = 1
        /// 1.5 XLM
        static let minAmountToCreateAssetAccount: Decimal = .init(stringValue: "1.5")!
    }
}

class StellarWalletManager: BaseManager, WalletManager {
    var txBuilder: StellarTransactionBuilder!
    var networkService: StellarNetworkService!
    var currentHost: String { networkService.host }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(accountId: wallet.address, isAsset: !cardTokens.isEmpty)
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

    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let fullReserve = response.assetBalances.isEmpty ? response.baseReserve * 2 : response.baseReserve * 3
        wallet.add(reserveValue: fullReserve)
        wallet.add(coinValue: response.balance - fullReserve)

        if cardTokens.isEmpty {
            response.assetBalances.forEach {
                let token = Token(
                    name: $0.code,
                    symbol: $0.code,
                    contractAddress: $0.issuer,
                    decimalCount: wallet.blockchain.decimalCount
                )
                wallet.add(tokenValue: $0.balance, for: token)
            }
        } else {
            for token in cardTokens {
                let assetBalance = response.assetBalances.first(where: { $0.code == token.symbol })?.balance ?? 0.0
                wallet.add(tokenValue: assetBalance, for: token)
            }
        }

        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension StellarWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return networkService.checkTargetAccount(address: transaction.destinationAddress, token: transaction.amount.type.token)
            .flatMap { [weak self] response -> AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> in
                guard let self else { return .emptyFail }

                return txBuilder.buildForSign(targetAccountResponse: response, transaction: transaction)
            }
            .flatMap { [weak self] buildForSignResponse -> AnyPublisher<(Data, (hash: Data, transaction: stellarsdk.TransactionXDR)), Error> in
                guard let self = self else { return .emptyFail }

                return signer.sign(
                    hash: buildForSignResponse.hash,
                    walletPublicKey: wallet.publicKey
                )
                .map { return ($0, buildForSignResponse) }.eraseToAnyPublisher()
            }
            .tryMap { [weak self] result throws -> String in
                guard let self = self else { throw WalletError.empty }

                guard let tx = self.txBuilder.buildForSend(signature: result.0, transaction: result.1.transaction) else {
                    throw WalletError.failedToBuildTx
                }

                return tx
            }
            .flatMap { [weak self] rawTransactionHash -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: rawTransactionHash).tryMap { [weak self] hash in
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
        networkService.getFee()
            .map { $0.map { Fee($0) } }
            .eraseToAnyPublisher()
    }
}

extension StellarWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(accountId: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

extension StellarWalletManager: ThenProcessable {}

extension StellarWalletManager: ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, addressType: ReserveAmountRestrictableAddressType) async throws {
        let isAccountCreated: Bool = try await {
            switch addressType {
            case .notCreated:
                return false
            case .address(let address):
                let account = try await networkService.checkTargetAccount(address: address, token: amount.type.token).async()
                return account.accountCreated
            }
        }()

        guard !isAccountCreated else {
            return
        }

        let reserveAmount = Amount(with: wallet.blockchain, value: Constants.minAmountToCreateCoinAccount)
        switch amount.type {
        case .coin:
            if amount < reserveAmount {
                throw ValidationError.reserve(amount: reserveAmount)
            }
        case .token:
            // From TxBuilder
            throw StellarError.assetNoAccountOnDestination
        case .reserve, .feeResource:
            break
        }
    }
}
