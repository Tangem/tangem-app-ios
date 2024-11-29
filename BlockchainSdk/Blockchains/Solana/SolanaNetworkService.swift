//
//  SolanaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 17.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SolanaSwift
import TangemFoundation

@available(iOS 13.0, *)
class SolanaNetworkService {
    var host: String {
        hostProvider.host
    }

    private let solanaSdk: Solana
    private let blockchain: Blockchain
    private let hostProvider: HostProvider

    init(solanaSdk: Solana, blockchain: Blockchain, hostProvider: HostProvider) {
        self.solanaSdk = solanaSdk
        self.blockchain = blockchain
        self.hostProvider = hostProvider
    }

    func getInfo(accountId: String, tokens: [Token]) -> AnyPublisher<SolanaAccountInfoResponse, Error> {
        Publishers.Zip3(
            mainAccountInfo(accountId: accountId),
            tokenAccountsInfo(accountId: accountId, programId: .tokenProgramId),
            tokenAccountsInfo(accountId: accountId, programId: .token2022ProgramId)
        )
        .tryMap { [weak self] mainAccount, splTokenAccounts, token2022Accounts in
            guard let self = self else {
                throw WalletError.empty
            }

            let tokenAccounts = splTokenAccounts + token2022Accounts
            return mapInfo(
                mainAccountInfo: mainAccount,
                tokenAccountsInfo: tokenAccounts,
                tokens: tokens
            )
        }
        .eraseToAnyPublisher()
    }

    func sendSol(
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        destinationAddress: String,
        signer: SolanaTransactionSigner
    ) -> AnyPublisher<TransactionID, Error> {
        solanaSdk.action.sendSOL(
            to: destinationAddress,
            amount: amount,
            computeUnitLimit: computeUnitLimit,
            computeUnitPrice: computeUnitPrice,
            allowUnfundedRecipient: true,
            signer: signer
        )
        .eraseToAnyPublisher()
    }

    func sendRaw(base64serializedTransaction: String) -> AnyPublisher<TransactionID, Error> {
        solanaSdk.api.sendTransaction(serializedTransaction: base64serializedTransaction)
            .eraseToAnyPublisher()
    }

    func sendSplToken(amount: UInt64, computeUnitLimit: UInt32?, computeUnitPrice: UInt64?, sourceTokenAddress: String, destinationAddress: String, token: Token, tokenProgramId: PublicKey, signer: SolanaTransactionSigner) -> AnyPublisher<TransactionID, Error> {
        checkIfSolanaAccount(destinationAddress: destinationAddress)
            .withWeakCaptureOf(self)
            .flatMap { service, isSolanaAccount in
                service.solanaSdk.action.sendSPLTokens(
                    mintAddress: token.contractAddress,
                    tokenProgramId: tokenProgramId,
                    decimals: Decimals(token.decimalCount),
                    from: sourceTokenAddress,
                    to: destinationAddress,
                    amount: amount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    allowUnfundedRecipient: isSolanaAccount,
                    signer: signer
                )
            }
            .eraseToAnyPublisher()
    }

    func getFeeForMessage(
        amount: UInt64,
        computeUnitLimit: UInt32?,
        computeUnitPrice: UInt64?,
        destinationAddress: String,
        fromPublicKey: PublicKey
    ) -> AnyPublisher<Decimal, Error> {
        solanaSdk.action.serializeMessage(
            to: destinationAddress,
            amount: amount,
            computeUnitLimit: computeUnitLimit,
            computeUnitPrice: computeUnitPrice,
            allowUnfundedRecipient: true,
            fromPublicKey: fromPublicKey
        )
        .flatMap { [solanaSdk] message, _ -> AnyPublisher<FeeForMessageResult, Error> in
            solanaSdk.api.getFeeForMessage(message)
        }
        .map { [blockchain] in
            Decimal($0.value) / blockchain.decimalValue
        }
        .eraseToAnyPublisher()
    }

    func transactionFee(numberOfSignatures: Int) -> AnyPublisher<Decimal, Error> {
        solanaSdk.api.getFees(commitment: nil)
            .tryMap { [weak self] fee in
                guard let self = self else {
                    throw WalletError.empty
                }

                guard let lamportsPerSignature = fee.feeCalculator?.lamportsPerSignature else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return Decimal(lamportsPerSignature) * Decimal(numberOfSignatures) / blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }

    // This fee is deducted from the transaction amount itself (!)
    func mainAccountCreationFee() -> AnyPublisher<Decimal, Error> {
        minimalBalanceForRentExemption(dataLength: 0)
    }

    func mainAccountCreationFee(dataLength: UInt64) -> AnyPublisher<Decimal, Error> {
        minimalBalanceForRentExemption(dataLength: dataLength)
    }

    func accountRentFeePerEpoch() -> AnyPublisher<Decimal, Error> {
        // https://docs.solana.com/developing/programming-model/accounts#calculation-of-rent
        let minimumAccountSizeInBytes = Decimal(128)
        let numberOfEpochs = Decimal(1)

        let rentInLamportPerByteEpoch: Decimal
        if blockchain.isTestnet {
            // Solana Testnet uses the same value as Mainnet.
            // The following value is for DEVNET. It is not mentioned in the docs and was obtained empirically.
            rentInLamportPerByteEpoch = Decimal(0.359375)
        } else {
            rentInLamportPerByteEpoch = Decimal(19.055441478439427)
        }
        let lamportsInSol = blockchain.decimalValue

        let rent = minimumAccountSizeInBytes * numberOfEpochs * rentInLamportPerByteEpoch / lamportsInSol

        return Just(rent).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func minimalBalanceForRentExemption(dataLength: UInt64 = 0) -> AnyPublisher<Decimal, Error> {
        // The accounts metadata size (128) is already factored in
        solanaSdk.api.getMinimumBalanceForRentExemption(dataLength: dataLength)
            .tryMap { [weak self] balanceInLamports in
                guard let self = self else {
                    throw WalletError.empty
                }

                return Decimal(balanceInLamports) / blockchain.decimalValue
            }
            .eraseToAnyPublisher()
    }

    func tokenProgramId(contractAddress: String) -> AnyPublisher<PublicKey, Error> {
        solanaSdk.api.getAccountInfo(account: contractAddress, decodedTo: AccountInfo.self)
            .tryMap { accountInfo in
                let tokenProgramIds: [PublicKey] = [
                    .tokenProgramId,
                    .token2022ProgramId,
                ]

                for tokenProgramId in tokenProgramIds {
                    if tokenProgramId.base58EncodedString == accountInfo.owner {
                        return tokenProgramId
                    }
                }
                throw BlockchainSdkError.failedToConvertPublicKey
            }
            .eraseToAnyPublisher()
    }

    private func mainAccountInfo(accountId: String) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> {
        solanaSdk.api.getAccountInfo(account: accountId, decodedTo: AccountInfo.self)
            .withWeakCaptureOf(self)
            .tryMap { service, info in
                let lamports = info.lamports
                let accountInfo = SolanaMainAccountInfoResponse(
                    balance: lamports,
                    accountExists: true,
                    rentExemption: 0
                )

                return accountInfo

                /*
                 // TODO: - https://tangem.atlassian.net/browse/IOS-8538

                 service.minimalBalanceForRentExemption(dataLength: info.space ?? 0)
                     .tryMap { rentExemption in
                         let lamports = info.lamports
                         let accountInfo = SolanaMainAccountInfoResponse(
                             balance: lamports,
                             accountExists: true,
                             rentExemption: rentExemption
                         )
                         return accountInfo
                     }
                 */
            }
            .tryCatch { (error: Error) -> AnyPublisher<SolanaMainAccountInfoResponse, Error> in
                if let solanaError = error as? SolanaError {
                    switch solanaError {
                    case .nullValue:
                        let info = SolanaMainAccountInfoResponse(balance: 0, accountExists: false, rentExemption: 0)
                        return Just(info)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    default:
                        break
                    }
                }

                throw error
            }.eraseToAnyPublisher()
    }

    private func tokenAccountsInfo(accountId: String, programId: PublicKey) -> AnyPublisher<[TokenAccount<AccountInfoData>], Error> {
        let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")

        return solanaSdk.api.getTokenAccountsByOwner(pubkey: accountId, programId: programId.base58EncodedString, configs: configs)
            .eraseToAnyPublisher()
    }

    private func mapInfo(
        mainAccountInfo: SolanaMainAccountInfoResponse,
        tokenAccountsInfo: [TokenAccount<AccountInfoData>],
        tokens: [Token]
    ) -> SolanaAccountInfoResponse {
        let balance = (Decimal(mainAccountInfo.balance) / blockchain.decimalValue).rounded(blockchain: blockchain)
        let accountExists = mainAccountInfo.accountExists

        let tokenInfoResponses: [SolanaTokenAccountInfoResponse] = tokenAccountsInfo.compactMap {
            guard
                let info = $0.account.data.value?.parsed.info,
                let token = tokens.first(where: { $0.contractAddress == info.mint }),
                let integerAmount = Decimal(stringValue: info.tokenAmount.amount)
            else {
                return nil
            }

            let address = $0.pubkey
            let mint = info.mint
            let amount = (integerAmount / token.decimalValue).rounded(scale: token.decimalCount)

            return SolanaTokenAccountInfoResponse(address: address, mint: mint, balance: amount, space: $0.account.space)
        }

        let tokenPairs = tokenInfoResponses.map { ($0.mint, $0) }
        let tokensByMint = Dictionary(tokenPairs) { token1, _ in
            return token1
        }

        return SolanaAccountInfoResponse(
            balance: balance,
            accountExists: accountExists,
            tokensByMint: tokensByMint,
            mainAccountRentExemption: mainAccountInfo.rentExemption
        )
    }

    /// Destination account checker
    /// - Parameter destinationAddress: destinationAddress to check
    /// - Returns: true if this address is solana base account, false if it is derived token account.
    /// - throws error if the account is not registered yet
    private func checkIfSolanaAccount(destinationAddress: String) -> AnyPublisher<Bool, Error> {
        solanaSdk.api.getAccountInfo(account: destinationAddress, decodedTo: AccountInfo.self)
            .tryMap { accountInfo in
                if accountInfo.owner == PublicKey.programId.base58EncodedString {
                    return true
                } else {
                    return false
                }
            }
            .tryCatch { error -> AnyPublisher<Bool, Error> in
                if let solanaError = error as? SolanaError {
                    switch solanaError {
                    case .nullValue:
                        return .justWithError(output: true)
                    default:
                        break
                    }
                }

                return .anyFail(error: error)
            }
            .eraseToAnyPublisher()
    }
}
