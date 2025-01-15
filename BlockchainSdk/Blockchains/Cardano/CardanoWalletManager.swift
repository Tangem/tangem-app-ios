//
//  CardanoWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

class CardanoWalletManager: BaseManager, WalletManager {
    var transactionBuilder: CardanoTransactionBuilder!
    var networkService: CardanoNetworkProvider!
    var currentHost: String { networkService.host }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(addresses: wallet.addresses.map { $0.value }, tokens: cardTokens)
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

    private func updateWallet(with response: CardanoAddressResponse) {
        let balance = Decimal(response.balance) / wallet.blockchain.decimalValue
        wallet.add(coinValue: balance)
        transactionBuilder.update(outputs: response.unspentOutputs)

        for (token, value) in response.tokenBalances {
            let balance = Decimal(value) / token.decimalValue
            wallet.add(tokenValue: balance, for: token)
        }

        wallet.removePendingTransaction { hash in
            let recentContains = response.recentTransactionsHashes.contains {
                $0.caseInsensitiveEquals(to: hash)
            }

            let outputsContains = response.unspentOutputs.contains {
                $0.transactionHash.caseInsensitiveEquals(to: hash)
            }

            return recentContains || outputsContains || response.unspentOutputs.isEmpty
        }
    }
}

extension CardanoWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        // Use Just to switch on global queue because we have async signing
        return Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] _ -> Data in
                guard let self else {
                    throw WalletError.empty
                }

                return try transactionBuilder.buildForSign(transaction: transaction)
            }
            .flatMap { [weak self] dataForSign -> AnyPublisher<SignatureInfo, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }

                return signer
                    .sign(hash: dataForSign, walletPublicKey: wallet.publicKey)
            }
            .tryMap { [weak self] signatureInfo -> Data in
                guard let self else {
                    throw WalletError.empty
                }

                return try transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
            }
            .flatMap { [weak self] builtTransaction -> AnyPublisher<String, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }

                return networkService
                    .send(transaction: builtTransaction)
                    .mapSendError(tx: builtTransaction.hexString.lowercased())
                    .eraseToAnyPublisher()
            }
            .tryMap { [weak self] hash in
                guard let self else {
                    throw WalletError.empty
                }

                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        do {
            let (uInt64Fee, parameters) = try transactionBuilder.getFee(amount: amount, destination: destination, source: defaultSourceAddress)
            var feeValue = Decimal(uInt64Fee)
            feeValue.round(scale: wallet.blockchain.decimalCount, roundingMode: .up)
            feeValue /= wallet.blockchain.decimalValue
            let feeAmount = Amount(with: wallet.blockchain, value: feeValue)
            let fee = Fee(feeAmount, parameters: parameters)
            return .justWithError(output: [fee])
        } catch {
            return .anyFail(error: error)
        }
    }
}

extension CardanoWalletManager: ThenProcessable {}

// MARK: - DustRestrictable

extension CardanoWalletManager: DustRestrictable {
    var dustValue: Amount {
        return Amount(with: wallet.blockchain, value: 1)
    }
}

// MARK: - WithdrawalNotificationProvider

extension CardanoWalletManager: WithdrawalNotificationProvider {
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning? {
        return nil
    }

    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification? {
        // We have to show the notification only when send the token
        guard amount.type.isToken else {
            return nil
        }

        guard let parameters = fee.parameters as? CardanoFeeParameters else {
            return nil
        }

        let value = Decimal(parameters.adaValue).moveLeft(decimals: wallet.blockchain.decimalCount)
        let amount = Amount(with: wallet.blockchain, value: value)
        return .cardanoWillBeSendAlongToken(amount: amount)
    }
}

// MARK: - CardanoTransferRestrictable

extension CardanoWalletManager: CardanoTransferRestrictable {
    func validateCardanoTransfer(amount: Amount, fee: Fee) throws {
        switch amount.type {
        case .coin:
            let hasTokensWithBalance = try transactionBuilder.hasTokensWithBalance(exclude: nil)

            guard hasTokensWithBalance else {
                // Skip this checking. Dust checking will be after
                return
            }

            try validateCardanoCoinWithdrawal(amount: amount, fee: fee)
        case .token:
            try validateCardanoTokenWithdrawal(amount: amount, fee: fee)
        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }

    private func validateCardanoCoinWithdrawal(amount: Amount, fee: Fee) throws {
        assert(!amount.type.isToken, "Only coin validation")

        guard wallet.amounts[.coin]?.value != nil else {
            throw ValidationError.balanceNotFound
        }

        guard let parameters = fee.parameters as? CardanoFeeParameters else {
            throw CardanoTransactionBuilderError.feeParametersNotFound
        }

        let minChange = try transactionBuilder.minChange(amount: amount)

        if parameters.change < minChange {
            let minChangeDecimal = Decimal(minChange) / wallet.blockchain.decimalValue
            let minimumAmount = Amount(with: wallet.blockchain, value: minChangeDecimal)

            throw ValidationError.cardanoHasTokens(minimumAmount: minimumAmount)
        }
    }

    private func validateCardanoTokenWithdrawal(amount: Amount, fee: Fee) throws {
        assert(amount.type.isToken, "Only token validation")

        guard var adaBalance = wallet.amounts[.coin]?.value else {
            throw ValidationError.balanceNotFound
        }

        guard let tokenBalance = wallet.amounts[amount.type]?.value else {
            throw ValidationError.balanceNotFound
        }

        // the fee will be spend in any case
        adaBalance -= fee.amount.value

        // 1. Check if there is enough ADA to send the token
        guard let parameters = fee.parameters as? CardanoFeeParameters else {
            throw CardanoTransactionBuilderError.feeParametersNotFound
        }

        let sendingAdaValueDecimal = Decimal(parameters.adaValue) / wallet.blockchain.decimalValue

        // Not enough balance to send token
        if sendingAdaValueDecimal > adaBalance {
            throw ValidationError.cardanoInsufficientBalanceToSendToken
        }

        // 2. Check if there is enough ADA to get a change with after transaction
        let minChange = try transactionBuilder.minChange(amount: amount)
        let isSendFullTokenAmount = amount.value == tokenBalance
        let willReceiveChange = try transactionBuilder.hasTokensWithBalance(
            exclude: isSendFullTokenAmount ? amount.type.token : nil
        )

        // If there not enough ada balance to change
        if willReceiveChange, parameters.change < minChange {
            throw ValidationError.cardanoInsufficientBalanceToSendToken
        }
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension CardanoWalletManager: StakeKitTransactionSender, StakeKitTransactionSenderProvider {
    typealias RawTransaction = Data

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try CardanoStakeKitTransactionHelper(
            transactionBuilder: transactionBuilder
        ).prepareForSign(transaction)
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        try CardanoStakeKitTransactionHelper(
            transactionBuilder: transactionBuilder
        ).prepareForSend(transaction, signature: signature)
    }

    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        let hex = rawTransaction.hexString
        return try await networkService.send(transaction: rawTransaction).async()
    }
}
