//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt
import TangemSdk
import TangemFoundation

// You can decode your CBOR transaction here: https://cbor.me
class CardanoTransactionBuilder {
    typealias FeeResult = (fee: UInt64, parameters: CardanoFeeParameters)

    private var outputs: [CardanoUnspentOutput] = []
    private let coinType: CoinType = .cardano

    init() {}
}

extension CardanoTransactionBuilder {
    func update(outputs: [CardanoUnspentOutput]) {
        self.outputs = outputs.filter { output in
            let containsIncorrectAssetNameHex = output.assets.contains(where: { asset in
                // We have to exclude assets with the incorrect hex name like `000de14064655f76696c6c69657273`
                // Which fails to meet utf8 standards
                String(data: Data(hexString: asset.assetNameHex), encoding: .utf8) == nil
            })

            if containsIncorrectAssetNameHex {
                Log.debug("CardanoTransactionBuilder will exclude output: \(output)")
            }

            return !containsIncorrectAssetNameHex
        }
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            Log.debug("CardanoPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signature: SignatureInfo) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signatures = DataVector()
        signatures.add(data: signature.signature)

        let publicKeys = DataVector()
        // WalletCore used here `.ed25519Cardano` curve with 128 bytes publicKey.
        // For more info see CardanoUtil
        let publicKey = signature.publicKey.trailingZeroPadding(toLength: CardanoUtil.extendedPublicKeyCount)
        publicKeys.add(data: publicKey)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CardanoSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            Log.debug("CardanoSigningOutput has a error: \(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        if output.encoded.isEmpty {
            throw WalletError.failedToBuildTx
        }

        return output.encoded
    }

    func getFee(amount: Amount, destination: String, source: String) throws -> FeeResult {
        switch amount.type {
        case .coin:
            return try getFeeCoin(amount: amount.uint64Amount, destination: destination, source: source)
        case .token(let token):
            return try getFeeToken(.init(token: token, amount: amount.uint64Amount), destination: destination, source: source)
        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }

    func minChange(amount: Amount) throws -> UInt64 {
        switch amount.type {
        case .coin:
            let hasTokens = outputs.contains { $0.assets.contains { $0.amount > 0 } }
            assert(hasTokens, "Use this only if wallet has tokens")

            return try minChange(exclude: nil)

        case .token(let token):
            return try minChange(token: token, uint64Amount: amount.uint64Amount)

        case .reserve, .feeResource:
            throw BlockchainSdkError.notImplemented
        }
    }

    func hasTokensWithBalance(exclude: Token?) throws -> Bool {
        try !assetsBalances(exclude: exclude).isEmpty
    }
}

// MARK: - Fee

private extension CardanoTransactionBuilder {
    func getFeeCoin(amount: UInt64, destination: String, source: String) throws -> FeeResult {
        let input = try buildCardanoSigningInput(
            source: source,
            destination: destination,
            option: .adaValue(amount),
            tokenAmount: nil
        )

        let parameters = CardanoFeeParameters(
            adaValue: input.plan.amount,
            change: input.plan.change,
            useMaxAmount: input.transferMessage.useMaxAmount
        )

        return (fee: input.plan.fee, parameters: parameters)
    }

    func getFeeToken(_ tokenAmount: TokenAmount, destination: String, source: String) throws -> FeeResult {
        let uint64AdaAmount = try buildCardanoMinAdaAmount(asset: asset(for: tokenAmount.token), amount: tokenAmount.amount)

        let balance = outputs.reduce(0) { $0 + $1.amount }
        // If we'll try to build the transaction with adaValue more then balance
        // We'll receive the error from the WalletCore
        let adaValue = min(balance, uint64AdaAmount)

        // First calculation with simple ada value
        var input = try buildCardanoSigningInput(
            source: source,
            destination: destination,
            option: .adaValue(adaValue),
            tokenAmount: tokenAmount
        )

        let minChange = try minChange(token: tokenAmount.token, uint64Amount: tokenAmount.amount)

        // If we don't have the balance for receive the minChange
        // We'll use max amount and have to recalculate fee without the change output
        if input.plan.change > 0, input.plan.change < minChange {
            input = try buildCardanoSigningInput(
                source: source,
                destination: destination,
                option: .useMaxAmount,
                tokenAmount: tokenAmount
            )
        }

        // The WalletCore can produce plan amount less than adaValue
        // sometimes it even may be workable and the network accepts the tx
        // But we decided that we would not allow this
        let sendingAdaAmount = max(input.plan.amount, adaValue)
        let parameters = CardanoFeeParameters(
            adaValue: sendingAdaAmount,
            change: input.plan.change,
            useMaxAmount: input.transferMessage.useMaxAmount
        )

        return (fee: input.plan.fee, parameters: parameters)
    }
}

// MARK: - Private

private extension CardanoTransactionBuilder {
    func minChange(token: Token, uint64Amount: UInt64) throws -> UInt64 {
        let asset = try asset(for: token)

        let tokenBalance: UInt64 = outputs.reduce(0) { partialResult, output in
            let amountInOutput = output.assets
                .filter { $0.policyID == asset.policyID }
                .reduce(0) { $0 + $1.amount }

            return partialResult + amountInOutput
        }

        let isSpendFullTokenAmount = tokenBalance == uint64Amount
        return try minChange(exclude: isSpendFullTokenAmount ? token : nil)
    }

    /// Use this method for calculate min value for the change output
    func minChange(exclude: Token?) throws -> UInt64 {
        let assetsBalances = try assetsBalances(exclude: exclude)

        let tokenBundle = CardanoTokenBundle.with {
            $0.token = assetsBalances.map { asset, balance in
                buildCardanoTokenAmount(asset: asset, amount: BigUInt(balance))
            }
        }

        let minChange = try CardanoMinAdaAmount(tokenBundle: tokenBundle.serializedData())
        return minChange
    }

    func assetsBalances(exclude: Token?) throws -> [CardanoUnspentOutput.Asset: UInt64] {
        let excludeAsset = try exclude.map { try asset(for: $0) }
        return outputs
            .flatMap {
                $0.assets.filter { $0 != excludeAsset }
            }
            .reduce(into: [:]) { result, asset in
                result[asset, default: 0] += asset.amount
            }
    }

    func asset(for token: Token) throws -> CardanoUnspentOutput.Asset {
        let assetFilter = CardanoAssetFilter(contractAddress: token.contractAddress)

        let asset = outputs
            .flatMap { $0.assets }
            .first { asset in
                assetFilter.isEqualToAssetWith(
                    policyId: asset.policyID,
                    assetNameHex: asset.assetNameHex
                )
            }

        guard let asset else {
            throw CardanoTransactionBuilderError.assetNotFound
        }

        return asset
    }

    // MARK: - Building

    func buildCardanoTokenAmount(asset: CardanoUnspentOutput.Asset, amount: BigUInt) -> CardanoTokenAmount {
        CardanoTokenAmount.with {
            $0.policyID = asset.policyID
            $0.assetNameHex = asset.assetNameHex
            // Should set amount as hex e.g. "01312d00" = 20000000
            $0.amount = amount.serialize()
        }
    }

    func buildCardanoMinAdaAmount(asset: CardanoUnspentOutput.Asset, amount: UInt64) throws -> UInt64 {
        let tokenBundle = CardanoTokenBundle.with {
            $0.token = [buildCardanoTokenAmount(asset: asset, amount: BigUInt(amount))]
        }
        let minAmount = try CardanoMinAdaAmount(tokenBundle: tokenBundle.serializedData())

        return minAmount
    }

    func buildCardanoSigningInput(transaction: Transaction) throws -> CardanoSigningInput {
        guard let parameters = transaction.fee.parameters as? CardanoFeeParameters else {
            throw CardanoTransactionBuilderError.feeParametersNotFound
        }

        return try buildCardanoSigningInput(
            source: transaction.sourceAddress,
            destination: transaction.destinationAddress,
            option: .parameters(parameters),
            tokenAmount: transaction.amount.tokenAmount
        )
    }

    func buildCardanoSigningInput(source: String, destination: String, option: BuildCardanoSigningInputOption, tokenAmount: TokenAmount?) throws -> CardanoSigningInput {
        if outputs.isEmpty {
            throw CardanoError.noUnspents
        }

        let utxos = outputs.map { output -> CardanoTxInput in
            CardanoTxInput.with {
                $0.outPoint.txHash = Data(hexString: output.transactionHash)
                $0.outPoint.outputIndex = output.outputIndex
                $0.address = output.address
                $0.amount = output.amount

                if !output.assets.isEmpty {
                    $0.tokenAmount = output.assets.map { asset in
                        CardanoTokenAmount.with {
                            $0.policyID = asset.policyID
                            $0.assetNameHex = asset.assetNameHex
                            // Amount in hexadecimal e.g. 2dc6c0 = 3000000
                            $0.amount = BigInt(asset.amount).serialize()
                        }
                    }
                }
            }
        }

        var input = try CardanoSigningInput.with {
            $0.utxos = utxos

            $0.transferMessage.toAddress = destination
            $0.transferMessage.changeAddress = source
            switch option {
            case .useMaxAmount:
                $0.transferMessage.useMaxAmount = true
            // We don't set the `transferMessage.amount` here because we `useMaxAmount`
            case .adaValue(let adaValue):
                $0.transferMessage.useMaxAmount = false
                $0.transferMessage.amount = adaValue
            case .parameters(let parameters):
                $0.transferMessage.useMaxAmount = parameters.useMaxAmount
                $0.transferMessage.amount = parameters.adaValue
            }

            if let tokenAmount {
                let tokenBundle = try CardanoTokenBundle.with {
                    let asset = try asset(for: tokenAmount.token)
                    $0.token = [buildCardanoTokenAmount(asset: asset, amount: BigUInt(tokenAmount.amount))]
                }

                $0.transferMessage.tokenAmount = tokenBundle
            }

            // Transaction validity time. Currently we are using absolute values.
            // At 16 April 2023 was 90007700 slot number.
            // We need to rework this logic to use relative validity time.
            // TODO: https://tangem.atlassian.net/browse/IOS-3471
            // This can be constructed using absolute ttl slot from `/metadata` endpoint.
            $0.ttl = 190000000
        }

        input.plan = AnySigner.plan(input: input, coin: coinType)

        if input.plan.error != .ok {
            Log.debug("CardanoSigningInput has a error: \(input.plan.error)")
            throw CardanoTransactionBuilderError.walletCoreError
        }

        return input
    }
}

private extension Amount {
    var tokenAmount: CardanoTransactionBuilder.TokenAmount? {
        guard case .token(let token) = type else {
            return nil
        }

        return .init(token: token, amount: uint64Amount)
    }

    var uint64Amount: UInt64 {
        value.moveRight(decimals: decimals).roundedDecimalNumber.uint64Value
    }
}

private extension CardanoTransactionBuilder {
    struct TokenAmount {
        let token: Token
        let amount: UInt64
    }

    enum BuildCardanoSigningInputOption {
        case useMaxAmount
        case adaValue(UInt64)
        case parameters(CardanoFeeParameters)
    }
}

enum CardanoTransactionBuilderError: Error {
    case assetNotFound
    case walletCoreError
    case feeParametersNotFound
}
