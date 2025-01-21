//
//  PolkadotWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 01.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import TangemSdk
import BigInt
import TangemFoundation

class PolkadotWalletManager: BaseManager, WalletManager {
    private let network: PolkadotNetwork
    var txBuilder: PolkadotTransactionBuilder!
    var networkService: PolkadotNetworkService!

    var currentHost: String { networkService.host }

    init(network: PolkadotNetwork, wallet: Wallet) {
        self.network = network
        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getInfo(for: wallet.address)
            .sink {
                switch $0 {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] info in
                self?.updateInfo(info)
            }
    }

    private func updateInfo(_ balance: BigUInt) {
        let decimals = wallet.blockchain.decimalCount
        guard
            let formatted = EthereumUtils.formatToPrecision(balance, numberDecimals: decimals, formattingDecimals: decimals, decimalSeparator: ".", fallbackToScientific: false),
            let value = Decimal(stringValue: formatted)
        else {
            return
        }

        wallet.add(amount: .init(with: wallet.blockchain, value: value))
        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension PolkadotWalletManager: TransactionSender {
    var allowsFeeSelection: Bool {
        false
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Publishers.Zip(
            networkService.blockchainMeta(for: transaction.sourceAddress),
            networkService.getInfo(for: transaction.destinationAddress)
        )
        .flatMap { [weak self] meta, destinationBalance -> AnyPublisher<Data, Error> in
            guard let self = self else {
                return .emptyFail
            }

            let existentialDeposit = network.existentialDeposit
            if transaction.amount < existentialDeposit, destinationBalance == BigUInt(0) {
                let message = Localization.noAccountPolkadot(existentialDeposit.string(roundingMode: .plain))
                return Fail(error: WalletError.noAccount(message: message, amountToCreate: existentialDeposit.value)).eraseToAnyPublisher()
            }

            return sign(amount: transaction.amount, destination: transaction.destinationAddress, meta: meta, signer: signer)
        }
        .flatMap { [weak self] image -> AnyPublisher<String, Error> in
            guard let self = self else {
                return .emptyFail
            }
            return networkService
                .submitExtrinsic(data: image)
                .mapSendError(tx: image.hexString)
                .eraseToAnyPublisher()
        }
        .tryMap { [weak self] hash in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
            self?.wallet.addPendingTransaction(record)
            return TransactionSendResult(hash: hash)
        }
        .eraseSendError()
        .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let blockchain = wallet.blockchain
        return networkService.blockchainMeta(for: destination)
            .flatMap { [weak self] meta -> AnyPublisher<Data, Error> in
                guard let self = self else {
                    return .emptyFail
                }
                return sign(amount: amount, destination: destination, meta: meta, signer: Ed25519DummyTransactionSigner())
            }
            .flatMap { [weak self] image -> AnyPublisher<UInt64, Error> in
                guard let self = self else {
                    return .emptyFail
                }
                return networkService.fee(for: image)
            }
            .map { intValue in
                let feeAmount = Amount(with: blockchain, value: Decimal(intValue) / blockchain.decimalValue)
                return [Fee(feeAmount)]
            }
            .eraseToAnyPublisher()
    }

    private func sign(amount: Amount, destination: String, meta: PolkadotBlockchainMeta, signer: TransactionSigner) -> AnyPublisher<Data, Error> {
        let wallet = wallet
        return Just(())
            .tryMap { [weak self] _ in
                guard let self = self else {
                    throw WalletError.empty
                }
                return try txBuilder.buildForSign(
                    amount: amount,
                    destination: destination,
                    meta: meta
                )
            }
            .flatMap { preImage in
                signer.sign(
                    hash: preImage,
                    walletPublicKey: wallet.publicKey
                )
            }
            .tryMap { [weak self] signature in
                guard let self = self else {
                    throw WalletError.empty
                }
                return try txBuilder.buildForSend(
                    amount: amount,
                    destination: destination,
                    meta: meta,
                    signature: signature
                )
            }
            .eraseToAnyPublisher()
    }
}

extension PolkadotWalletManager: ExistentialDepositProvider {
    var existentialDeposit: Amount {
        network.existentialDeposit
    }
}

extension PolkadotWalletManager: MinimumBalanceRestrictable {
    var minimumBalance: Amount {
        network.existentialDeposit
    }
}

extension PolkadotWalletManager: ThenProcessable {}

// MARK: - Dummy transaction signer

private class Ed25519DummyTransactionSigner: TransactionSigner {
    private let privateKey = Data(repeating: 0, count: 32)

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Fail(error: WalletError.failedToGetFee).eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        Just<Data>(hash)
            .tryMap { hash in
                try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).signature(for: hash)
            }
            .eraseToAnyPublisher()
    }

    func sign(
        dataToSign: [DerivationPath: (Data, Data)],
        seedKey: Data
    ) -> AnyPublisher<[(Data, Data)], Error> {
        Fail(error: WalletError.failedToGetFee).eraseToAnyPublisher()
    }
}
