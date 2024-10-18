//
//  EthereumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk
import WalletCore

// Decoder: https://rawtxdecode.in
class EthereumTransactionBuilder {
    private let chainId: Int
    private let coinType: CoinType = .ethereum

    init(chainId: Int) {
        self.chainId = chainId
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let preSigningOutput = try buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let output = try buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    func buildDummyTransactionForL1(destination: String, value: String?, data: Data?, fee: Fee) throws -> Data {
        let valueData = BigUInt(Data(hex: value ?? "0x0"))
        switch fee.amount.type {
        case .coin:
            let input = try buildSigningInput(
                destination: destination,
                coinAmount: valueData,
                fee: fee,
                // The nonce for the dummy transaction won't be used later, so we can just mock it with any value
                nonce: 1,
                data: data
            )
            return try buildTxCompilerPreSigningOutput(input: input).data

        case .token(let token):
            let data = TransferERC20TokenMethod(destination: destination, amount: valueData).data
            let input = try buildSigningInput(
                destination: token.contractAddress,
                coinAmount: .zero,
                fee: fee,
                // The nonce for the dummy transaction won't be used later, so we can just mock it with any value
                nonce: 1,
                data: data
            )

            return try buildTxCompilerPreSigningOutput(input: input).data
        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }

    // MARK: - Transaction data builder

    func buildForApprove(spender: String, amount: Decimal) -> Data {
        let bigUInt = EthereumUtils.mapToBigUInt(amount)
        return ApproveERC20TokenMethod(spender: spender, amount: bigUInt).data
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        if !amount.type.isToken {
            return Data()
        }

        guard let bigUInt = amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        let method = TransferERC20TokenMethod(destination: destination, amount: bigUInt)
        return method.data
    }

    func buildSigningInput(destination: String, coinAmount: BigUInt, fee: Fee, nonce: Int, data: Data?) throws -> EthereumSigningInput {
        guard nonce >= 0 else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        guard let feeParameters = fee.parameters as? EthereumFeeParameters else {
            throw EthereumTransactionBuilderError.feeParametersNotFound
        }

        let input = EthereumSigningInput.with { input in
            input.chainID = BigUInt(chainId).serialize()
            input.nonce = BigUInt(nonce).serialize()
            input.toAddress = destination

            input.transaction = .with { transaction in
                input.toAddress = destination
                transaction.contractGeneric = .with {
                    $0.amount = coinAmount.serialize()
                    if let data {
                        $0.data = data
                    }
                }
            }

            switch feeParameters.parametersType {
            case .eip1559(let eip1559Parameters):
                // EIP-1559. https://eips.ethereum.org/EIPS/eip-1559
                input.txMode = .enveloped
                input.gasLimit = eip1559Parameters.gasLimit.serialize()
                input.maxFeePerGas = eip1559Parameters.maxFeePerGas.serialize()
                input.maxInclusionFeePerGas = eip1559Parameters.priorityFee.serialize()
            case .legacy(let legacyParameters):
                input.txMode = .legacy
                input.gasLimit = legacyParameters.gasLimit.serialize()
                input.gasPrice = legacyParameters.gasPrice.serialize()
            }
        }

        return input
    }

    func buildTxCompilerPreSigningOutput(input: EthereumSigningInput) throws -> TxCompilerPreSigningOutput {
        let txInputData = try input.serializedData()
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            Log.debug("EthereumPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw EthereumTransactionBuilderError.walletCoreError(message: preSigningOutput.errorMessage)
        }

        return preSigningOutput
    }

    func buildSigningOutput(input: EthereumSigningInput, signatureInfo: SignatureInfo) throws -> EthereumSigningOutput {
        guard signatureInfo.signature.count == Constants.signatureSize else {
            throw EthereumTransactionBuilderError.invalidSignatureCount
        }

        let decompressed = try Secp256k1Key(with: signatureInfo.publicKey).decompress()
        let secp256k1Signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshal = try secp256k1Signature.unmarshal(with: decompressed, hash: signatureInfo.hash)
        let txInputData = try input.serializedData()

        // As we use the chainID in the transaction according to EIP-155
        // WalletCore will use formula to calculate `V`.
        // v = CHAIN_ID * 2 + 35
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md

        // It's strange but we can't use `unmarshal.v` here because WalletCore throw a error.
        // And we have to add one zero byte to the signature because
        // WalletCore has a validation on the signature count.
        // // https://github.com/tangem/wallet-core/blob/996bd5ab37f27e7f6e240a4ec9d0788dfb124e89/src/PublicKey.h#L35
        let v = BigUInt(unmarshal.v) - 27
        let encodedV = v == .zero ? Data([UInt8.zero]) : v.serialize()
        let signature = unmarshal.r + unmarshal.s + encodedV

        let signatures = DataVector()
        signatures.add(data: signature)

        let publicKeys = DataVector()
        publicKeys.add(data: decompressed)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try EthereumSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            Log.debug("EthereumSigningOutput has a error: \(output.errorMessage)")
            throw EthereumTransactionBuilderError.walletCoreError(message: output.errorMessage)
        }

        if output.encoded.isEmpty {
            throw EthereumTransactionBuilderError.transactionEncodingFailed
        }

        return output
    }
}

private extension EthereumTransactionBuilder {
    func buildSigningInput(transaction: Transaction) throws -> EthereumSigningInput {
        guard let amountValue = transaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        guard let parameters = transaction.params as? EthereumTransactionParams else {
            throw EthereumTransactionBuilderError.transactionParamsNotFound
        }

        guard let nonce = parameters.nonce else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        switch transaction.amount.type {
        case .coin:
            return try buildSigningInput(
                destination: transaction.destinationAddress,
                coinAmount: amountValue,
                fee: transaction.fee,
                nonce: nonce,
                data: parameters.data
            )
        case .token(let token):
            let contract = transaction.contractAddress ?? token.contractAddress
            let method = TransferERC20TokenMethod(destination: transaction.destinationAddress, amount: amountValue)
            let data = parameters.data ?? method.data

            return try buildSigningInput(
                destination: contract,
                coinAmount: .zero,
                fee: transaction.fee,
                nonce: nonce,
                data: data
            )

        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }
}

extension EthereumTransactionBuilder {
    private enum Constants {
        static let signatureSize = 64
    }
}

enum EthereumTransactionBuilderError: LocalizedError {
    case feeParametersNotFound
    case transactionParamsNotFound
    case invalidSignatureCount
    case invalidAmount
    case invalidNonce
    case transactionEncodingFailed
    case walletCoreError(message: String)
    case invalidStakingTransaction

    var errorDescription: String? {
        switch self {
        case .feeParametersNotFound:
            return "feeParametersNotFound"
        case .transactionParamsNotFound:
            return "transactionParamsNotFound"
        case .invalidAmount:
            return "invalidAmount"
        case .invalidNonce:
            return "invalidNonce"
        case .invalidSignatureCount:
            return "invalidSignatureCount"
        case .transactionEncodingFailed:
            return "transactionEncodingFailed"
        case .walletCoreError(let message):
            return "walletCoreError: \(message)"
        case .invalidStakingTransaction:
            return "invalidStakingTransaction"
        }
    }
}
