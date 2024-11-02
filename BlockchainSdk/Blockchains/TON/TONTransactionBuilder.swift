//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import WalletCore
import TonSwift
import BigInt
import TangemFoundation

/// Transaction builder for TON wallet
final class TONTransactionBuilder {
    // MARK: - Properties

    /// Sequence number of transactions
    var sequenceNumber: Int = 0

    // MARK: - Private Properties

    private let wallet: Wallet

    /// Only TrustWallet signer input transfer key (not for use public implementation)
    private var inputPrivateKey: Curve25519.Signing.PrivateKey

    private var modeTransactionConstant: UInt32 {
        UInt32(TheOpenNetworkSendMode.payFeesSeparately.rawValue | TheOpenNetworkSendMode.ignoreActionPhaseErrors.rawValue)
    }

    // MARK: - Init

    init(wallet: Wallet) {
        self.wallet = wallet
        inputPrivateKey = .init()
    }

    // MARK: - Implementation

    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    ///   - jettonWalletAddress: Address of jetton wallet, required for jetton transaction
    /// - Returns: TheOpenNetworkSigningInput for sign transaction with external signer
    func buildForSign(
        amount: Amount,
        destination: String,
        jettonWalletAddress: String? = nil,
        params: TONTransactionParams? = nil
    ) throws -> TheOpenNetworkSigningInput {
        return try input(
            amount: amount,
            destination: destination,
            jettonWalletAddress: jettonWalletAddress,
            params: params
        )
    }

    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - output: TW output of message
    /// - Returns: External message for TON blockchain
    func buildForSend(output: TheOpenNetworkSigningOutput) throws -> String {
        return output.encoded
    }

    // MARK: - Private Implementation

    /// Build WalletCore input for sign transaction
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    ///   - jettonWalletAddress: Address of jetton wallet, required for jetton transaction
    /// - Returns: TheOpenNetworkSigningInput for sign transaction with external signer
    private func input(
        amount: Amount,
        destination: String,
        jettonWalletAddress: String? = nil,
        params: TONTransactionParams?
    ) throws -> TheOpenNetworkSigningInput {
        switch amount.type {
        case .coin, .reserve:
            let transfer = try transfer(amountValue: amount.value, destination: destination, params: params)

            // Sign input with dummy key of Curve25519 private key
            return TheOpenNetworkSigningInput.with {
                $0.transfer = transfer
                $0.privateKey = inputPrivateKey.rawRepresentation
            }
        case .token(let token):
            guard let jettonWalletAddress else {
                fatalError("Wallet address must be set for jetton trasaction")
            }
            let transfer = try jettonTransfer(
                amount: amount,
                destination: destination,
                jettonWalletAddress: jettonWalletAddress,
                token: token,
                params: params
            )

            // Sign input with dummy key of Curve25519 private key
            return TheOpenNetworkSigningInput.with {
                $0.jettonTransfer = transfer
                $0.privateKey = inputPrivateKey.rawRepresentation
            }
        case .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }

    /// Create transfer message transaction to blockchain
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkTransfer message for Input transaction of TON blockchain
    private func transfer(
        amountValue: Decimal,
        destination: String,
        params: TONTransactionParams?
    ) throws -> TheOpenNetworkTransfer {
        TheOpenNetworkTransfer.with {
            $0.walletVersion = TheOpenNetworkWalletVersion.walletV4R2
            $0.dest = destination
            $0.amount = (amountValue * wallet.blockchain.decimalValue).uint64Value
            $0.sequenceNumber = UInt32(sequenceNumber)
            $0.mode = modeTransactionConstant
            $0.bounceable = false
            $0.comment = params?.memo ?? ""
        }
    }

    /// Create jetton transfer message transaction to blockchain
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    ///   - jettonWalletAddress: Address of sender's jetton wallet
    /// - Returns: TheOpenNetworkTransfer message for Input transaction of TON blockchain
    private func jettonTransfer(
        amount: Amount,
        destination: String,
        jettonWalletAddress: String,
        token: Token,
        params: TONTransactionParams?
    ) throws -> TheOpenNetworkJettonTransfer {
        let transferData = try transfer(
            amountValue: Constants.jettonTransferProcessingFee,
            destination: jettonWalletAddress, // we need to put SENDER's jetton wallet address here, see comment for TheOpenNetworkJettonTransfer -> transfer
            params: params
        )
        return TheOpenNetworkJettonTransfer.with {
            $0.transfer = transferData
            $0.jettonAmount = (amount.value * token.decimalValue).uint64Value
            $0.toOwner = destination
            $0.responseAddress = wallet.address
            $0.forwardAmount = 1 // needs some amount to send "jetton transfer notification", use minimum
        }
    }
}

// MARK: - Dummy Cases

extension TONTransactionBuilder {
    struct DummyInput {
        let wallet: Wallet
        let inputPrivateKey: Curve25519.Signing.PrivateKey
        let sequenceNumber: Int
    }

    /// Use only dummy tested or any dummy cases!
    static func makeDummyBuilder(with input: DummyInput) -> TONTransactionBuilder {
        let txBuilder = TONTransactionBuilder(wallet: input.wallet)
        txBuilder.inputPrivateKey = input.inputPrivateKey
        txBuilder.sequenceNumber = input.sequenceNumber
        return txBuilder
    }
}

extension TONTransactionBuilder {
    enum Constants {
        static let jettonTransferProcessingFee: Decimal = 0.05 // used to cover token transfer fees, commonly used value after TON fee reduction, actual costs now are ~10 times less, excess is returned
    }
}
