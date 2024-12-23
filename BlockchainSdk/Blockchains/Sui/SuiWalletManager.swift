//
// SuiWalletManager.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 28.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SuiWalletManager: BaseManager, WalletManager {
    let networkService: SuiNetworkService
    let transactionBuilder: SuiTransactionBuilder

    init(wallet: Wallet, networkService: SuiNetworkService, transactionBuilder: SuiTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService.getBalance(address: wallet.address, coinType: .sui, cursor: nil)
            .sink(receiveCompletion: { [weak self] completionSubscriptions in
                if case .failure(let error) = completionSubscriptions {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] result in
                switch result {
                case .success(let coins):
                    self?.updateWallet(coins: coins)
                    completion(.success(()))
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            })
    }

    func updateWallet(coins: [SuiGetCoins.Coin]) {
        let objects = coins.compactMap {
            SuiCoinObject.from($0)
        }

        let totalBalance = objects.filter({ $0.coinType == SUIUtils.CoinType.sui.string }).reduce(into: Decimal(0)) { partialResult, coin in
            partialResult += coin.balance
        }

        let coinValue = totalBalance / wallet.blockchain.decimalValue

        if coinValue != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }
        
        for token in cardTokens {
            let tokenBalance = objects.filter({ $0.coinType == token.contractAddress }).reduce(into: Decimal(0)) { partialResult, coin in
                partialResult += coin.balance
            }
            let decimalTokenBalance = tokenBalance / token.decimalValue
            wallet.add(tokenValue: decimalTokenBalance, for: token)
        }

        wallet.add(coinValue: coinValue)
        transactionBuilder.update(coins: objects)
    }
}

extension SuiWalletManager: BlockchainDataProvider {
    var currentHost: String {
        networkService.host
    }
}

extension SuiWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        return networkService.getReferenceGasPrice()
            .withWeakCaptureOf(self)
            .flatMap { manager, referencedGasPrice -> AnyPublisher<SuiInspectTransaction, any Error> in
                guard let decimalGasPrice = Decimal(stringValue: referencedGasPrice) else {
                    return .anyFail(error: WalletError.failedToParseNetworkResponse())
                }

                return manager.estimateFee(amount: amount, destination: destination, referenceGasPrice: decimalGasPrice)
            }
            .withWeakCaptureOf(self)
            .tryMap { manager, inspectTransaction in
                guard inspectTransaction.effects.isSuccess() else {
                    throw WalletError.failedToGetFee
                }

                guard let usedGasPrice = Decimal(stringValue: inspectTransaction.input.gasData.price),
                      let computationCost = Decimal(stringValue: inspectTransaction.effects.gasUsed.computationCost),
                      let storageCost = Decimal(stringValue: inspectTransaction.effects.gasUsed.storageCost) else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                let budget = computationCost + storageCost
                let feeAmount = Amount(with: manager.wallet.blockchain, value: budget / manager.wallet.blockchain.decimalValue)

                let params = SuiFeeParameters(gasPrice: usedGasPrice, gasBudget: budget)
                return [Fee(feeAmount, parameters: params)]
            }
            .eraseToAnyPublisher()
    }

    private func estimateFee(amount: Amount, destination: String, referenceGasPrice: Decimal) -> AnyPublisher<SuiInspectTransaction, any Error> {
        return Result {
            try transactionBuilder.buildForInspect(amount: amount, destination: destination, referenceGasPrice: referenceGasPrice)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, base64tx: String) -> AnyPublisher<SuiInspectTransaction, Error> in
            manager.networkService.dryTransaction(transaction: base64tx)
        }
        .eraseToAnyPublisher()
    }
}

extension SuiWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Result {
            try transactionBuilder.buildForSign(transaction: transaction)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { (manager, dataHash: Data) -> AnyPublisher<SignatureInfo, Error> in
            signer.sign(hash: dataHash, walletPublicKey: manager.wallet.publicKey)
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, signatureInfo -> (txBytes: String, signature: String) in
            let output = try manager.transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo.signature)
            return output
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, builtTransaction -> AnyPublisher<SuiExecuteTransaction, Error> in
            return manager.networkService
                .sendTransaction(transaction: builtTransaction.txBytes, signature: builtTransaction.signature)
                .mapSendError(tx: builtTransaction.txBytes)
                .eraseToAnyPublisher()
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, tx in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: tx.digest)

            manager.wallet.addPendingTransaction(record)

            return TransactionSendResult(hash: tx.digest)
        }
        .eraseSendError()
        .eraseToAnyPublisher()
    }
}
