//
//  ChiaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import TangemFoundation

final class ChiaTransactionBuilder {
    // MARK: - Private Properties

    /// Max BLS hashes count to handle by single iOS NFS session. IPhone 7/7+ doesn’t support BLS signing due to hardware limitations.
    let maxInputCount = 15

    private let isTestnet: Bool
    private let walletPublicKey: Data
    private var coinSpends: [ChiaCoinSpend] = []
    private var unspentCoins: [ChiaCoin] = []

    private var genesisChallenge: Data {
        Data(hex: GenesisChallenge.challenge(isTestnet: blockchain.isTestnet))
    }

    private var blockchain: Blockchain {
        .chia(testnet: isTestnet)
    }

    // MARK: - Init

    init(isTestnet: Bool, walletPublicKey: Data, unspentCoins: [ChiaCoin] = []) {
        self.isTestnet = isTestnet
        self.walletPublicKey = walletPublicKey
        self.unspentCoins = unspentCoins
    }

    // MARK: - Implementation

    func setUnspent(coins: [ChiaCoin]) {
        let sortedCoins = coins.sorted {
            $0.amount > $1.amount
        }

        unspentCoins = Array(sortedCoins.prefix(maxInputCount))
    }

    /// This limitation is due to the number of possible signatures
    /// - Returns: Max amount for withdraw of use the number of signatures
    func availableAmount() -> Amount {
        let decimalBalance = unspentCoins.map { Decimal($0.amount) }.reduce(0, +)
        let maxAmountBalance = decimalBalance / blockchain.decimalValue
        return Amount(with: blockchain, value: maxAmountBalance)
    }

    func buildForSign(transaction: Transaction) throws -> [Data] {
        let availableInputValue = availableAmount()

        guard !unspentCoins.isEmpty, transaction.amount <= availableInputValue else {
            throw WalletError.failedToBuildTx
        }

        let change = try calculateChange(
            transaction: transaction,
            unspentCoins: unspentCoins
        )

        coinSpends = try toChiaCoinSpends(
            change: change,
            destination: transaction.destinationAddress,
            source: transaction.sourceAddress,
            amount: transaction.amount
        )

        let hashesForSign = try coinSpends.map {
            let solutionHash = try ClvmProgram.Decoder(
                programBytes: Data(hex: $0.solution).dropFirst(1).dropLast(1).bytes
            ).deserialize().hash()

            return try (solutionHash + $0.coin.calculateId() + genesisChallenge).hashAugScheme(with: walletPublicKey)
        }

        return hashesForSign
    }

    func buildToSend(signatures: [Data]) throws -> ChiaSpendBundle {
        let aggregatedSignature = try BLSUtils().aggregate(signatures: signatures.map { $0.hexString.addHexPrefix() })

        return ChiaSpendBundle(
            aggregatedSignature: aggregatedSignature,
            coinSpends: coinSpends
        )
    }

    /// Calculate standart costs for fee transaction
    /// - Parameter amount: Amount of send transaction
    /// - Returns: Sum value for transaction
    func getTransactionCost(amount: Amount) -> Int64 {
        let decimalAmount = (amount.value * blockchain.decimalValue).roundedDecimalNumber.int64Value
        let decimalBalance = unspentCoins.map { $0.amount }.reduce(0, +)
        let change = decimalBalance - decimalAmount
        let numberOfCoinsCreated: Int = change > 0 ? 2 : 1

        return Int64((unspentCoins.count * Constants.coinSpendCost) + (numberOfCoinsCreated * Constants.createCoinCost))
    }

    // MARK: - Private Implementation

    private func calculateChange(transaction: Transaction, unspentCoins: [ChiaCoin]) throws -> Int64 {
        let fullAmount = unspentCoins.map { $0.amount }.reduce(0, +)
        let transactionAmount = (transaction.amount.value * blockchain.decimalValue).roundedDecimalNumber.int64Value
        let transactionFeeAmount = (transaction.fee.amount.value * blockchain.decimalValue).roundedDecimalNumber.int64Value
        let changeAmount = fullAmount - (transactionAmount + transactionFeeAmount)

        return changeAmount
    }

    private func toChiaCoinSpends(change: Int64, destination: String, source: String, amount: Amount) throws -> [ChiaCoinSpend] {
        let coinSpends = unspentCoins.map {
            ChiaCoinSpend(
                coin: $0,
                puzzleReveal: ChiaPuzzleUtils().getPuzzleHash(from: walletPublicKey).hexString.addHexPrefix().lowercased(),
                solution: ""
            )
        }

        let sendAmount = (amount.value * blockchain.decimalValue).roundedDecimalNumber.int64Value
        let sendCondition = try createCoinCondition(for: destination, with: sendAmount)
        let changeCondition = try change != 0 ? createCoinCondition(for: source, with: change) : nil

        let solution: [ChiaCondition] = [sendCondition, changeCondition].compactMap { $0 }
        coinSpends[0].solution = try solution.toSolution().hexString.addHexPrefix().lowercased()

        for coinSpend in coinSpends.dropFirst(1) {
            coinSpend.solution = try [RemarkCondition()].toSolution().hexString.addHexPrefix().lowercased()
        }

        return coinSpends
    }

    private func createCoinCondition(for address: String, with amount: Int64) throws -> CreateCoinCondition {
        return try CreateCoinCondition(
            destinationPuzzleHash: ChiaPuzzleUtils().getPuzzleHash(from: address),
            amount: amount
        )
    }
}

// MARK: - Constants

private extension ChiaTransactionBuilder {
    /// Cost constants from empirically case
    enum Constants {
        static let coinSpendCost: Int = 4500000
        static let createCoinCost: Int = 2400000
    }

    enum GenesisChallenge {
        private static let mainnet = "ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb"
        private static let testnet = "ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2"

        static func challenge(isTestnet: Bool) -> String {
            return isTestnet ? testnet : mainnet
        }
    }
}

// MARK: - Helpers

private extension Array where Element == ChiaCondition {
    func toSolution() throws -> Data {
        let conditions = ClvmProgram.from(list: map { $0.toProgram() })
        let solutionArguments = ClvmProgram.from(list: [conditions]) // might be more than one for other puzzles

        return try solutionArguments.serialize()
    }
}

private extension Data {
    func hashAugScheme(with publicKey: Data) throws -> Data {
        try Data(hex: BLSUtils().augSchemeMplG2Map(publicKey: publicKey.hexString.lowercased(), message: hexString.lowercased()))
    }
}
