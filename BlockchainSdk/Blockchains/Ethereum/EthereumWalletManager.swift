//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya

class EthereumWalletManager: BaseManager, WalletManager, EthereumTransactionSigner {
    let txBuilder: EthereumTransactionBuilder
    let networkService: EthereumNetworkService
    let addressConverter: EthereumAddressConverter
    let allowsFeeSelection: Bool

    var currentHost: String { networkService.host }

    init(
        wallet: Wallet,
        addressConverter: EthereumAddressConverter,
        txBuilder: EthereumTransactionBuilder,
        networkService: EthereumNetworkService,
        allowsFeeSelection: Bool
    ) {
        self.txBuilder = txBuilder
        self.networkService = networkService
        self.addressConverter = addressConverter
        self.allowsFeeSelection = allowsFeeSelection

        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = addressConverter.convertToETHAddressPublisher(wallet.address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService
                    .getInfo(address: convertedAddress, tokens: walletManager.cardTokens)
            }
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }

    // It can't be into extension because it will be overridden in the `OptimismWalletManager`
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        let fromPublisher = addressConverter.convertToETHAddressPublisher(defaultSourceAddress)
        let destinationPublisher = addressConverter.convertToETHAddressPublisher(destination)

        return fromPublisher
            .zip(destinationPublisher)
            .withWeakCaptureOf(self)
            .flatMap { (walletManager, convertedAddresses) -> AnyPublisher<[Fee], Error> in
                let (from, destination) = convertedAddresses
                if walletManager.wallet.blockchain.supportsEIP1559 {
                    return walletManager.getEIP1559Fee(from: from, destination: destination, value: value, data: data)
                } else {
                    return walletManager.getLegacyFee(from: from, destination: destination, value: value, data: data)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // It can't be into extension because it will be overridden in the `MantleWalletManager`
    /// Build and sign transaction
    /// - Parameters:
    /// - Returns: The hex of the raw transaction ready to be sent over the network
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        Publishers.Zip(
            addressConverter.convertToETHAddressesPublisher(in: transaction),
            networkService.getPendingTxCount(transaction.sourceAddress)
        )
        .map { convertedTransaction, nonce in
            convertedTransaction.then { convertedTransaction in
                let ethParams = convertedTransaction.params as? EthereumTransactionParams
                convertedTransaction.params = ethParams?.with(nonce: nonce) ?? EthereumTransactionParams(nonce: nonce)
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, convertedTransaction in
            Result {
                try walletManager.txBuilder.buildForSign(transaction: convertedTransaction)
            }
            .publisher
            .withWeakCaptureOf(walletManager)
            .flatMap { walletManager, hashToSign in
                signer.sign(hash: hashToSign, walletPublicKey: walletManager.wallet.publicKey)
            }
            .withWeakCaptureOf(walletManager)
            .tryMap { walletManager, signatureInfo -> String in
                try walletManager.txBuilder
                    .buildForSend(
                        transaction: convertedTransaction,
                        signatureInfo: signatureInfo
                    )
                    .hexString
                    .lowercased()
                    .addHexPrefix()
            }
        }
        .eraseToAnyPublisher()
    }
    
    // It can't be into extension because it will be overridden in the `MantleWalletManager`
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        let toPublisher = addressConverter.convertToETHAddressPublisher(to)
        let fromPublisher = addressConverter.convertToETHAddressPublisher(from)

        return toPublisher
            .zip(fromPublisher)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddresses in
                let (to, from) = convertedAddresses
                return walletManager.networkService
                    .getGasLimit(to: to, from: from, value: value, data: data)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - EthereumNetworkProvider

extension EthereumWalletManager: EthereumNetworkProvider {
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error> {
        let ownerPublisher = addressConverter.convertToETHAddressPublisher(owner)
        let spenderPublisher = addressConverter.convertToETHAddressPublisher(spender)
        let contractAddressPublisher = addressConverter.convertToETHAddressPublisher(contractAddress)

        return ownerPublisher
            .zip(spenderPublisher, contractAddressPublisher)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddresses in
                let (owner, spender, contractAddress) = convertedAddresses
                return walletManager.networkService.getAllowance(owner: owner, spender: spender, contractAddress: contractAddress)
            }
            .tryMap { response in
                if let allowance = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) {
                    return allowance
                }

                throw ETHError.failedToParseAllowance
            }
            .eraseToAnyPublisher()
    }

    // Balance

    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getBalance(convertedAddress)
            }
            .eraseToAnyPublisher()
    }

    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Result<Decimal, Error>], Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getTokensBalance(convertedAddress, tokens: tokens)
            }
            .eraseToAnyPublisher()
    }

    // Nonce

    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getTxCount(convertedAddress)
            }
            .eraseToAnyPublisher()
    }

    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        addressConverter.convertToETHAddressPublisher(address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getPendingTxCount(convertedAddress)
            }
            .eraseToAnyPublisher()
    }

    // Fee

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> {
        networkService.getFeeHistory()
    }
}

// MARK: - Private

private extension EthereumWalletManager {
    func getEIP1559Fee(from: String, destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getEIP1559Fee(
            to: destination,
            from: from,
            value: value,
            data: data?.hexString.addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.mapEIP1559Fee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }

    func mapEIP1559Fee(response: EthereumEIP1559FeeResponse) -> [Fee] {
        let feeParameters = [
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.low.max,
                priorityFee: response.fees.low.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.market.max,
                priorityFee: response.fees.market.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.fast.max,
                priorityFee: response.fees.fast.priority
            ),
        ]

        let fees = feeParameters.map { parameters in
            let feeValue = parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)
            let amount = Amount(with: wallet.blockchain, value: feeValue)

            return Fee(amount, parameters: parameters)
        }

        return fees
    }

    func getLegacyFee(from: String, destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getLegacyFee(
            to: destination,
            from: from,
            value: value,
            data: data?.hexString.addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.mapLegacyFee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }

    func mapLegacyFee(response: EthereumLegacyFeeResponse) -> [Fee] {
        let feeParameters = [
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.lowGasPrice
            ),
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.marketGasPrice
            ),
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.fastGasPrice
            ),
        ]

        let fees = feeParameters.map { parameters in
            let feeValue = parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)
            let amount = Amount(with: wallet.blockchain, value: feeValue)

            return Fee(amount, parameters: parameters)
        }

        return fees
    }

    func updateWallet(with response: EthereumInfoResponse) {
        wallet.add(coinValue: response.balance)
        
        for tokenBalance in response.tokenBalances {
            switch tokenBalance.value {
            case .success(let value):
                wallet.add(tokenValue: value, for: tokenBalance.key)
            case .failure:
                wallet.clearAmount(for: tokenBalance.key)
            }
        }

        if response.txCount == response.pendingTxCount {
            wallet.clearPendingTransaction()
        } else if response.pendingTxs.isEmpty {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.clearPendingTransaction()
            response.pendingTxs.forEach {
                let mapper = PendingTransactionRecordMapper()
                let transaction = mapper.mapToPendingTransactionRecord($0, blockchain: wallet.blockchain)
                wallet.addPendingTransaction(transaction)
            }
        }
    }
}

// MARK: - TransactionFeeProvider

extension EthereumWalletManager: TransactionFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee],Error> {
        addressConverter.convertToETHAddressPublisher(destination)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedDestination -> AnyPublisher<[Fee],Error> in
                switch amount.type {
                case .coin:
                    guard let hexAmount = amount.encodedForSend else {
                        return .anyFail(error: BlockchainSdkError.failedToLoadFee)
                    }

                    return walletManager.getFee(destination: convertedDestination, value: hexAmount, data: nil)
                case .token(let token):
                    do {
                        let transferData = try walletManager.buildForTokenTransfer(destination: convertedDestination, amount: amount)
                        return walletManager.getFee(destination: token.contractAddress, value: nil, data: transferData)
                    } catch {
                        return .anyFail(error: error)
                    }
                case .reserve, .feeResource:
                    return .anyFail(error: BlockchainSdkError.notImplemented)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - TransactionSender

extension EthereumWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return addressConverter.convertToETHAddressesPublisher(in: transaction)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedTransaction in
                walletManager.sign(convertedTransaction, signer: signer)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransaction in
                walletManager.networkService.send(transaction: rawTransaction)
                    .mapSendError(tx: rawTransaction)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                walletManager.wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: hash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
}

// MARK: - SignatureCountValidator

extension EthereumWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        addressConverter.convertToETHAddressPublisher(wallet.address)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, convertedAddress in
                walletManager.networkService.getSignatureCount(address: convertedAddress)
            }
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - EthereumTransactionDataBuilder

extension EthereumWalletManager: EthereumTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Decimal) throws -> Data {
        let spender = try addressConverter.convertToETHAddress(spender)
        return txBuilder.buildForApprove(spender: spender, amount: amount)
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        let destination = try addressConverter.convertToETHAddress(destination)
        return try txBuilder.buildForTokenTransfer(destination: destination, amount: amount)
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension EthereumWalletManager: StakeKitTransactionSender, StakeKitTransactionSenderProvider {
    typealias RawTransaction = String

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try EthereumStakeKitTransactionHelper(transactionBuilder: txBuilder).prepareForSign(transaction)
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        try EthereumStakeKitTransactionHelper(transactionBuilder: txBuilder)
            .prepareForSend(stakingTransaction: transaction, signatureInfo: signature)
            .hexString
            .lowercased()
            .addHexPrefix()
    }

    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        try await networkService.send(transaction: rawTransaction).async()
    }
}
