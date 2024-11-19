//
//  Stellart=TransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine

@available(iOS 13.0, *)
class StellarTransactionBuilder {
    var sequence: Int64?
    var useTimebounds = true
    // for tests
    var specificTxTime: TimeInterval?

    private let walletPublicKey: Data
    private let isTestnet: Bool

    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }

    func buildForSign(targetAccountResponse: StellarTargetAccountResponse, transaction: Transaction) -> AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> {
        guard let destinationKeyPair = try? KeyPair(accountId: transaction.destinationAddress),
              let sourceKeyPair = try? KeyPair(accountId: transaction.sourceAddress) else {
            return Fail(error: WalletError.failedToBuildTx)
                .eraseToAnyPublisher()
        }

        let memo = (transaction.params as? StellarTransactionParams)?.memo ?? Memo.text("")

        let result: (Data, stellarsdk.TransactionXDR)
        do {
            let isAccountCreated = targetAccountResponse.accountCreated
            let amountToCreateAccount: Decimal = StellarWalletManager.Constants.minAmountToCreateCoinAccount

            if transaction.amount.type == .coin {
                if !isAccountCreated, transaction.amount.value < amountToCreateAccount {
                    throw WalletError.noAccount(message: StellarError.xlmCreateAccount.localizedDescription, amountToCreate: amountToCreateAccount)
                }

                let operation = isAccountCreated ? try PaymentOperation(
                    sourceAccountId: transaction.sourceAddress,
                    destinationAccountId: transaction.destinationAddress,
                    asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                    amount: transaction.amount.value
                ) :
                    CreateAccountOperation(sourceAccountId: nil, destination: destinationKeyPair, startBalance: transaction.amount.value)

                result = try serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)

            } else if transaction.amount.type.isToken {
                guard let contractAddress = transaction.contractAddress, let keyPair = try? KeyPair(accountId: contractAddress),
                      let asset = createNonNativeAsset(code: transaction.amount.currencySymbol, issuer: keyPair) else {
                    throw WalletError.failedToBuildTx
                }

                guard isAccountCreated else {
                    throw StellarError.assetNoAccountOnDestination
                }

                guard targetAccountResponse.trustlineCreated else {
                    throw StellarError.assetNoTrustline
                }

                if transaction.amount.value > 0 {
                    let operation = try PaymentOperation(
                        sourceAccountId: transaction.sourceAddress,
                        destinationAccountId: transaction.destinationAddress,
                        asset: asset,
                        amount: transaction.amount.value
                    )

                    result = try serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
                } else {
                    guard let changeTrustAsset = asset.toChangeTrustAsset() else {
                        throw WalletError.failedToBuildTx
                    }

                    let operation = ChangeTrustOperation(sourceAccountId: transaction.sourceAddress, asset: changeTrustAsset, limit: Decimal(string: "900000000000.0000000"))
                    result = try serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
                }

            } else {
                throw WalletError.failedToBuildTx
            }

        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func buildForSend(signature: Data, transaction: TransactionXDR) -> String? {
        var transaction = transaction
        let hint = walletPublicKey.suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint), signature: signature)
        transaction.addSignature(signature: decoratedSignature)
        let envelope = try? transaction.encodedEnvelope()
        return envelope
    }

    private func createNonNativeAsset(code: String, issuer: KeyPair) -> Asset? {
        if code.count >= 1, code.count <= 4 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: code, issuer: issuer)
        } else if code.count >= 5, code.count <= 12 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: code, issuer: issuer)
        } else {
            return nil
        }
    }

    private func serializeOperation(_ operation: stellarsdk.Operation, sourceKeyPair: KeyPair, memo: Memo) throws -> (hash: Data, transaction: stellarsdk.TransactionXDR) {
        guard let xdrOperation = try? operation.toXDR(),
              let seqNumber = sequence else {
            throw WalletError.failedToBuildTx
        }

        // Extended the interval from 2 minutes to 5 to make sure the transaction lives longer
        // and has more chance of getting through when the network is under heavy load
        let currentTime = specificTxTime ?? Date().timeIntervalSince1970
        let minTime = currentTime - 2.5 * 60.0
        let maxTime = currentTime + 2.5 * 60.0

        let cond: PreconditionsXDR = useTimebounds ? .time(TimeBoundsXDR(minTime: UInt64(minTime), maxTime: UInt64(maxTime))) : .none
        let tx = TransactionXDR(
            sourceAccount: sourceKeyPair.publicKey,
            seqNum: seqNumber + 1,
            cond: cond,
            memo: memo.toXDR(),
            operations: [xdrOperation]
        )

        let network = isTestnet ? Network.testnet : Network.public
        guard let hash = try? tx.hash(network: network) else {
            throw WalletError.failedToBuildTx
        }

        return (hash, tx)
    }
}

extension Asset {
    func toChangeTrustAsset() -> ChangeTrustAsset? {
        ChangeTrustAsset(type: type, code: code, issuer: issuer)
    }
}
