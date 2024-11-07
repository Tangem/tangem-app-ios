//
//  CasperWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CasperWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        false
    }

    // MARK: - Private Implementation

    private let networkService: CasperNetworkService
    private let transactionBuilder: CasperTransactionBuilder

    // MARK: - Init

    init(wallet: Wallet, networkService: CasperNetworkService, transactionBuilder: CasperTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Manager Implementation

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        let balanceInfoPublisher = networkService
            .getBalance(address: wallet.address)

        cancellable = balanceInfoPublisher
            .withWeakCaptureOf(self)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { walletManager, balanceInfo in
                walletManager.updateWallet(balanceInfo: balanceInfo)
            })
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        let amountFee = Amount(with: wallet.blockchain, type: .coin, value: Constants.constantFeeValue)
        return .justWithError(output: [Fee(amountFee)])
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let timestamp = getCurrentTimestamp()
        let hashForSign: Data

        do {
            hashForSign = try transactionBuilder.buildForSign(
                transaction: transaction,
                timestamp: timestamp
            )
        } catch {
            return .sendTxFail(error: error)
        }

        return signer
            .sign(hash: hashForSign.sha256(), walletPublicKey: wallet.publicKey)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, signature in
                try walletManager.transactionBuilder.buildForSend(
                    transaction: transaction,
                    timestamp: timestamp,
                    signature: signature
                )
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransactionData -> AnyPublisher<String, Error> in
                walletManager.networkService.putDeploy(rawData: rawTransactionData)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, transactionHash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionHash)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: transactionHash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func updateWallet(balanceInfo: CasperBalance) {
        if balanceInfo.value != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }

        wallet.add(coinValue: balanceInfo.value)
    }

    private func getCurrentTimestamp() -> String {
        let timestamp = Date().timeIntervalSince1970
        let tE = String(timestamp).components(separatedBy: ".")
        let mili = tE[1]
        let indexMili = mili.index(mili.startIndex, offsetBy: 3)
        let miliStr = mili[..<indexMili]
        let myTimeInterval = TimeInterval(timestamp)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        let timeStr = String(time.description)
        let timeElements = timeStr.components(separatedBy: " ")
        let newTimeStr = timeElements[0] + "T" + timeElements[1] + ".\(miliStr)Z"
        return newTimeStr
    }
}

// MARK: - MinimumAmountRestrictable

extension CasperWalletManager: MinimumAmountRestrictable {
    var minimumAmountRestrictValue: Amount {
        Amount(with: wallet.blockchain, value: Constants.minimumAmountRestrictValue)
    }
}

private extension CasperWalletManager {
    enum Constants {
        static let constantFeeValue = Decimal(stringValue: "0.1")!
        static let minimumAmountRestrictValue = Decimal(stringValue: "2.5")!
    }
}
