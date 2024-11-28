//
//  SolanaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import SolanaSwift
import TangemFoundation

class SolanaWalletManager: BaseManager, WalletManager {
    var solanaSdk: Solana!
    var networkService: SolanaNetworkService!

    var currentHost: String { networkService.host }

    var usePriorityFees = !NFCUtils.isPoorNfcQualityDevice

    // It is taken into account in the calculation of the account rent commission for the sender
    private var mainAccountRentExemption: Decimal = 0

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let transactionIDs = wallet.pendingTransactions.map { $0.hash }

        cancellable = networkService.getInfo(accountId: wallet.address, tokens: cardTokens, transactionIDs: transactionIDs)
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] info in
                self?.updateWallet(info: info)
            }
    }

    private func updateWallet(info: SolanaAccountInfoResponse) {
        mainAccountRentExemption = info.mainAccountRentExemption

        wallet.add(coinValue: info.balance)

        for cardToken in cardTokens {
            let mintAddress = cardToken.contractAddress
            let balance = info.tokensByMint[mintAddress]?.balance ?? Decimal(0)
            wallet.add(tokenValue: balance, for: cardToken)
        }

        wallet.removePendingTransaction { hash in
            info.confirmedTransactionIDs.contains(hash)
        }
    }
}

extension SolanaWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sendPublisher: AnyPublisher<TransactionID, Error>
        switch transaction.amount.type {
        case .coin:
            sendPublisher = sendSol(transaction, signer: signer)
        case .token(let token):
            sendPublisher = sendSplToken(transaction, token: token, signer: signer)
        case .reserve, .feeResource:
            return .sendTxFail(error: WalletError.empty)
        }

        return sendPublisher
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
        destinationAccountInfo(destination: destination, amount: amount)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, destinationAccountInfo in
                let feeParameters = walletManager.feeParameters(destinationAccountInfo: destinationAccountInfo)
                let decimalValue: Decimal = pow(10, amount.decimals)
                let intAmount = (amount.value * decimalValue).rounded().uint64Value

                return walletManager.networkService.getFeeForMessage(
                    amount: intAmount,
                    computeUnitLimit: feeParameters.computeUnitLimit,
                    computeUnitPrice: feeParameters.computeUnitPrice,
                    destinationAddress: destination,
                    fromPublicKey: PublicKey(data: walletManager.wallet.publicKey.blockchainKey)!
                )
                .map { (feeForMessage: $0, feeParameters: feeParameters) }
            }
            .withWeakCaptureOf(self)
            .map { walletManager, feeInfo -> [Fee] in
                let totalFee = feeInfo.feeForMessage + feeInfo.feeParameters.accountCreationFee
                let amount = Amount(with: walletManager.wallet.blockchain, type: .coin, value: totalFee)

                return [Fee(amount, parameters: feeInfo.feeParameters)]
            }
            .eraseToAnyPublisher()
    }

    private func sendSol(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: WalletError.failedToSendTx)
        }

        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)

        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value

        return networkService.sendSol(
            amount: intAmount,
            computeUnitLimit: solanaFeeParameters.computeUnitLimit,
            computeUnitPrice: solanaFeeParameters.computeUnitPrice,
            destinationAddress: transaction.destinationAddress,
            signer: signer
        )
    }

    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: WalletError.failedToSendTx)
        }

        let decimalAmount = transaction.amount.value * token.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        let tokenProgramIdPublisher = networkService.tokenProgramId(contractAddress: token.contractAddress)

        return tokenProgramIdPublisher
            .flatMap { [weak self] tokenProgramId -> AnyPublisher<TransactionID, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }

                guard
                    let associatedSourceTokenAccountAddress = associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress, tokenProgramId: tokenProgramId)
                else {
                    return .anyFail(error: BlockchainSdkError.failedToConvertPublicKey)
                }

                return networkService.sendSplToken(
                    amount: intAmount,
                    computeUnitLimit: solanaFeeParameters.computeUnitLimit,
                    computeUnitPrice: solanaFeeParameters.computeUnitPrice,
                    sourceTokenAddress: associatedSourceTokenAccountAddress,
                    destinationAddress: transaction.destinationAddress,
                    token: token,
                    tokenProgramId: tokenProgramId,
                    signer: signer
                )
            }
            .eraseToAnyPublisher()
    }

    private func associatedTokenAddress(accountAddress: String, mintAddress: String, tokenProgramId: PublicKey) -> String? {
        guard
            let accountPublicKey = PublicKey(string: accountAddress),
            let tokenMintPublicKey = PublicKey(string: mintAddress),
            case .success(let associatedSourceTokenAddress) = PublicKey.associatedTokenAddress(walletAddress: accountPublicKey, tokenMintAddress: tokenMintPublicKey, tokenProgramId: tokenProgramId)
        else {
            return nil
        }

        return associatedSourceTokenAddress.base58EncodedString
    }
}

private extension SolanaWalletManager {
    /// Combine `accountCreationFeePublisher`, `accountExistsPublisher` and `minimalBalanceForRentExemption`
    func destinationAccountInfo(destination: String, amount: Amount) -> AnyPublisher<DestinationAccountInfo, Error> {
        let accountExistsPublisher = accountExists(destination: destination, amountType: amount.type)
        let rentExemptionBalancePublisher = networkService.minimalBalanceForRentExemption()

        return Publishers.Zip(accountExistsPublisher, rentExemptionBalancePublisher)
            .withWeakCaptureOf(self)
            .flatMap { manager, values in
                let accountExistsInfo = values.0
                let rentExemption = values.1

                if accountExistsInfo.isExist || amount.type == .coin && amount.value >= rentExemption {
                    return Just(DestinationAccountInfo(accountExists: accountExistsInfo.isExist, accountCreationFee: 0))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return manager
                        .accountCreationFeePublisher(amount: amount, with: accountExistsInfo.space)
                        .map {
                            DestinationAccountInfo(
                                accountExists: accountExistsInfo.isExist,
                                accountCreationFee: $0
                            )
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func accountExists(destination: String, amountType: Amount.AmountType) -> AnyPublisher<AccountExistsInfo, Error> {
        let tokens: [Token] = amountType.token.map { [$0] } ?? []

        return networkService
            .getInfo(accountId: destination, tokens: tokens, transactionIDs: [])
            .map { info in
                switch amountType {
                case .coin:
                    return AccountExistsInfo(isExist: info.accountExists, space: nil)
                case .token(let token):
                    let existingTokenAccount = info.tokensByMint[token.contractAddress]
                    return AccountExistsInfo(isExist: existingTokenAccount != nil, space: existingTokenAccount?.space)
                case .reserve, .feeResource:
                    return AccountExistsInfo(isExist: false, space: nil)
                }
            }
            .eraseToAnyPublisher()
    }

    func accountCreationFeePublisher(amount: Amount, with space: UInt64?) -> AnyPublisher<Decimal, Error> {
        switch amount.type {
        case .coin:
            // Include the fee if the amount is less than it
            return networkService.mainAccountCreationFee()
                .map { accountCreationFee in
                    if amount.value < accountCreationFee {
                        return accountCreationFee
                    } else {
                        return .zero
                    }
                }
                .eraseToAnyPublisher()
        case .token:
            return networkService.mainAccountCreationFee(dataLength: space ?? 0)
        case .reserve, .feeResource:
            return .anyFail(error: BlockchainSdkError.failedToLoadFee)
        }
    }

    func feeParameters(destinationAccountInfo: DestinationAccountInfo) -> SolanaFeeParameters {
        let computeUnitLimit: UInt32?
        let computeUnitPrice: UInt64?

        if usePriorityFees {
            // https://www.helius.dev/blog/priority-fees-understanding-solanas-transaction-fee-mechanics
            computeUnitLimit = destinationAccountInfo.accountExists ? 200_000 : 400_000
            computeUnitPrice = destinationAccountInfo.accountExists ? 1_000_000 : 500_000
        } else {
            computeUnitLimit = nil
            computeUnitPrice = nil
        }

        return SolanaFeeParameters(
            computeUnitLimit: computeUnitLimit,
            computeUnitPrice: computeUnitPrice,
            accountCreationFee: destinationAccountInfo.accountCreationFee
        )
    }
}

extension SolanaWalletManager: RentProvider {
    func minimalBalanceForRentExemption() -> AnyPublisher<Amount, Error> {
        let amountValue = Amount(with: wallet.blockchain, value: mainAccountRentExemption)
        return CurrentValueSubject(amountValue).eraseToAnyPublisher()
    }

    func rentAmount() -> AnyPublisher<Amount, Error> {
        networkService.accountRentFeePerEpoch()
            .tryMap { [weak self] fee in
                guard let self = self else {
                    throw WalletError.empty
                }

                let blockchain = wallet.blockchain
                return Amount(with: blockchain, type: .coin, value: fee)
            }
            .eraseToAnyPublisher()
    }
}

extension SolanaWalletManager: TransactionValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try validateInternal(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateInternal(amount: amount, fee: fee)
    }

    private func validateInternal(amount: Amount, fee: Fee) throws {
        if let balance = wallet.amounts[.coin]  {
            let minimalBalanceForRentExemptionValue = Amount(with: wallet.blockchain, value: mainAccountRentExemption)
            let remainingBalance = balance.value - (amount.value + fee.amount.value)

            if remainingBalance > 0, remainingBalance < minimalBalanceForRentExemptionValue.value {
                throw ValidationError.remainingAmountIsLessThanRentFee(amount: minimalBalanceForRentExemptionValue)
            }
        }
        // default implementation
        try validateAmounts(amount: amount, fee: fee.amount)
    }
}

extension SolanaWalletManager: ThenProcessable {}

private extension SolanaWalletManager {
    struct DestinationAccountInfo {
        let accountExists: Bool
        let accountCreationFee: Decimal
    }

    struct AccountExistsInfo {
        let isExist: Bool
        let space: UInt64?
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension SolanaWalletManager: StakeKitTransactionSender, StakeKitTransactionSenderProvider {
    typealias RawTransaction = String

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        SolanaStakeKitTransactionHelper().prepareForSign(transaction.unsignedData)
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        SolanaStakeKitTransactionHelper().prepareForSend(transaction.unsignedData, signature: signature.signature)
    }

    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        try await networkService.sendRaw(base64serializedTransaction: rawTransaction).async()
    }
}
