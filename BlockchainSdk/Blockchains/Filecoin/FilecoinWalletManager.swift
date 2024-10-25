//
//  FilecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 30.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine

class FilecoinWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    private let networkService: FilecoinNetworkService
    private let transactionBuilder: FilecoinTransactionBuilder
    
    private var nonce: UInt64 = 0
    
    init(
        wallet: Wallet,
        networkService: FilecoinNetworkService,
        transactionBuilder: FilecoinTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService
            .getAccountInfo(address: wallet.address)
            .withWeakCaptureOf(self)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { walletManager, accountInfo in
                    if accountInfo.nonce != walletManager.nonce {
                        walletManager.wallet.clearPendingTransaction()
                    }
                    
                    walletManager.wallet.add(
                        amount: Amount(
                            with: .filecoin,
                            type: .coin,
                            value: accountInfo.balance / walletManager.wallet.blockchain.decimalValue
                        )
                    )
                    
                    walletManager.nonce = accountInfo.nonce
                }
            )
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        guard let bigUIntValue = amount.bigUIntValue else {
            return .anyFail(error: WalletError.failedToGetFee)
        }
        
        return networkService
            .getAccountInfo(address: wallet.address)
            .map { [address = wallet.address] accountInfo in
                FilecoinMessage(
                    from: address,
                    to: destination,
                    value: String(bigUIntValue, radix: 10),
                    nonce: accountInfo.nonce,
                    gasLimit: nil,
                    gasFeeCap: nil,
                    gasPremium: nil
                )
            }
            .withWeakCaptureOf(networkService)
            .flatMap { networkService, message in
                networkService.getEstimateMessageGas(message: message)
            }
            .withWeakCaptureOf(self)
            .tryMap { (walletManager: FilecoinWalletManager, gasInfo) -> [Fee] in
                guard let gasFeeCapDecimal = Decimal(stringValue: gasInfo.gasFeeCap) else {
                    throw WalletError.failedToGetFee
                }
                
                let gasLimitDecimal = Decimal(gasInfo.gasLimit)
                
                return [
                    Fee(
                        Amount(
                            with: .filecoin,
                            type: .coin,
                            value: gasLimitDecimal * gasFeeCapDecimal / walletManager.wallet.blockchain.decimalValue
                        ),
                        parameters: FilecoinFeeParameters(
                            gasLimit: gasInfo.gasLimit,
                            gasFeeCap: BigUInt(stringLiteral: gasInfo.gasFeeCap),
                            gasPremium: BigUInt(stringLiteral: gasInfo.gasPremium)
                        )
                    )
                ]
            }
            .eraseToAnyPublisher()
    }
    
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        networkService
            .getAccountInfo(address: wallet.address)
            .withWeakCaptureOf(transactionBuilder)
            .tryMap { transactionBuilder, accountInfo in
                let hashToSign = try transactionBuilder.buildForSign(
                    transaction: transaction,
                    nonce: accountInfo.nonce
                )
                return (hashToSign, accountInfo.nonce)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, args in
                let (hashToSign, nonce) = args
                return signer
                    .sign(hash: hashToSign, walletPublicKey: walletManager.wallet.publicKey)
                    .withWeakCaptureOf(walletManager)
                    .tryMap { walletManager, signature in
                        try walletManager.transactionBuilder.buildForSend(
                            transaction: transaction,
                            nonce: nonce,
                            signatureInfo: SignatureInfo(
                                signature: signature,
                                publicKey: walletManager.wallet.publicKey.blockchainKey,
                                hash: hashToSign
                            )
                        )
                    }
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, message in
                walletManager.networkService
                    .submitTransaction(signedMessage: message)
                    .mapSendError(tx: try? JSONEncoder().encode(message).utf8String)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, txId in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: txId)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: txId)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
}
