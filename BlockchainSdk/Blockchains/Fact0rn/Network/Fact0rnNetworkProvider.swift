//
//  Fact0rnNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 31.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class Fact0rnNetworkProvider: BitcoinNetworkProvider {
    // MARK: - Properties

    var supportsTransactionPush: Bool { false }
    var host: String { provider.host }

    // MARK: - Private Properties

    private let provider: ElectrumWebSocketProvider
    private let decimalValue: Decimal
    private let decimalCount: Int

    // MARK: - Init

    init(provider: ElectrumWebSocketProvider, decimalValue: Decimal, decimalCount: Int) {
        self.provider = provider
        self.decimalValue = decimalValue
        self.decimalCount = decimalCount
    }

    // MARK: - BitcoinNetworkProvider Implementation

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, any Error> {
        let defferedScriptHash = Deferred {
            return Future { promise in
                let result = Result { try Fact0rnAddressService.addressToScriptHash(address: address) }
                promise(result)
            }
        }

        return defferedScriptHash
            .withWeakCaptureOf(self)
            .flatMap { provider, scriptHash in
                provider.getAddressInfo(identifier: .scriptHash(scriptHash))
            }
            .withWeakCaptureOf(self)
            .flatMap { provider, accountInfo in
                let pendingTransactionsPublisher = provider.getPendingTransactions(address: address, with: accountInfo.outputs)
                return pendingTransactionsPublisher
                    .map { pendingTranactions in
                        Fact0rnAccountModel(addressInfo: accountInfo, pendingTransactions: pendingTranactions)
                    }
            }
            .withWeakCaptureOf(self)
            .tryMap { provider, account in
                let outputScriptData = try Fact0rnAddressService.addressToScript(address: address).scriptData
                return try provider.mapBitcoinResponse(account: account, outputScript: outputScriptData.hexString)
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, any Error> {
        let minimalEstimateFeePublisher = estimateFee(confirmations: Constants.minimalFeeBlockAmount)
        let normalEstimateFeePublisher = estimateFee(confirmations: Constants.normalFeeBlockAmount)
        let priorityEstimateFeePublisher = estimateFee(confirmations: Constants.priorityFeeBlockAmount)

        return Publishers.Zip3(
            minimalEstimateFeePublisher,
            normalEstimateFeePublisher,
            priorityEstimateFeePublisher
        )
        .withWeakCaptureOf(self)
        .map { provider, values in
            let minimalSatoshiPerByte = provider.calculateFee(value: values.0, size: Constants.minimalFeeBlockAmount)
            let normalSatoshiPerByte = provider.calculateFee(value: values.1, size: Constants.normalFeeBlockAmount)
            let prioritySatoshiPerByte = provider.calculateFee(value: values.2, size: Constants.priorityFeeBlockAmount)

            return BitcoinFee(
                minimalSatoshiPerByte: minimalSatoshiPerByte,
                normalSatoshiPerByte: normalSatoshiPerByte,
                prioritySatoshiPerByte: prioritySatoshiPerByte
            )
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, any Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            return try await provider.send(transactionHex: transaction)
        }
        .eraseToAnyPublisher()
    }

    func push(transaction: String) -> AnyPublisher<String, any Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            return try await provider.send(transactionHex: transaction)
        }
        .eraseToAnyPublisher()
    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, any Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            let txHistory = try await provider.getTxHistory(identifier: .scriptHash(address))
            return txHistory.count
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func getAddressInfo(identifier: ElectrumWebSocketProvider.Identifier) -> AnyPublisher<ElectrumAddressInfo, Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            async let balance = provider.getBalance(identifier: identifier)
            async let unspents = provider.getUnspents(identifier: identifier)

            return try await ElectrumAddressInfo(
                balance: Decimal(balance.confirmed) / decimalValue,
                outputs: unspents.map { unspent in
                    ElectrumUTXO(
                        position: unspent.txPos,
                        hash: unspent.txHash,
                        value: unspent.value,
                        height: unspent.height
                    )
                }
            )
        }
        .eraseToAnyPublisher()
    }

    private func getPendingTransactions(
        address: String,
        with unspents: [ElectrumUTXO]
    ) -> AnyPublisher<[PendingTransaction], Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            let unconfirmedUnspents = unspents.filter(\.isNonConfirmed)

            let result: [PendingTransaction] = try await withThrowingTaskGroup(of: PendingTransaction.self) { group in
                var pendingTransactions: [PendingTransaction] = []

                for unspent in unconfirmedUnspents {
                    group.addTask {
                        try await self.createPendingTransaction(unspent: unspent, address: address)
                    }
                }

                for try await value in group {
                    pendingTransactions.append(value)
                }

                return pendingTransactions
            }

            return result
        }
        .eraseToAnyPublisher()
    }

    private func estimateFee(confirmations count: Int = 10) -> AnyPublisher<Decimal, Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            return try await provider.estimateFee(block: count)
        }
        .eraseToAnyPublisher()
    }

    private func send(transactionHex: String) -> AnyPublisher<String, Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            return try await provider.send(transactionHex: transactionHex)
        }
        .eraseToAnyPublisher()
    }

    private func getTransactionInfo(hash: String) -> AnyPublisher<ElectrumDTO.Response.Transaction, Error> {
        Future.async { [weak self] in
            guard let self else {
                throw BlockchainSdkError.noAPIInfo
            }

            return try await provider.getTransaction(hash: hash)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func mapBitcoinResponse(account: Fact0rnAccountModel, outputScript: String) throws -> BitcoinResponse {
        let hasUnconfirmed = account.addressInfo.balance != .zero
        let unspentOutputs = mapUnspent(outputs: account.addressInfo.outputs, outputScript: outputScript)

        return BitcoinResponse(
            balance: account.addressInfo.balance,
            hasUnconfirmed: hasUnconfirmed,
            pendingTxRefs: account.pendingTransactions,
            unspentOutputs: unspentOutputs
        )
    }

    private func mapUnspent(outputs: [ElectrumUTXO], outputScript: String) -> [BitcoinUnspentOutput] {
        outputs.map {
            BitcoinUnspentOutput(
                transactionHash: $0.hash,
                outputIndex: $0.position,
                amount: $0.value.uint64Value,
                outputScript: outputScript
            )
        }
    }

    private func createPendingTransaction(unspent: ElectrumUTXO, address: String) async throws -> PendingTransaction {
        let transaction = try await provider.getTransaction(hash: unspent.hash)
        return toPendingTx(transaction: transaction, address: address, decimalValue: decimalValue)
    }

    private func toPendingTx(
        transaction: ElectrumDTO.Response.Transaction,
        address: String,
        decimalValue: Decimal
    ) -> PendingTransaction {
        var source: String = .unknown
        var destination: String = .unknown
        var value: Decimal?
        var isIncoming = false

        let vin = transaction.vin
        let vout = transaction.vout

        if let _ = vin.first(where: { $0.address?.contains(address) ?? false }),
           let txDestination = vout.first(where: { $0.scriptPubKey.address != address }) {
            destination = txDestination.scriptPubKey.address
            source = address
            value = txDestination.value
        } else if let txDestination = vout.first(where: { $0.scriptPubKey.address == address }),
                  let txSource = vin.first(where: { $0.address != address }) {
            isIncoming = true
            destination = address
            source = txSource.address ?? .unknown
            value = txDestination.value
        }

        let fee = transaction.fee ?? .zero

        return PendingTransaction(
            hash: transaction.hash,
            destination: destination,
            value: (value ?? 0) / decimalValue,
            source: source,
            fee: fee / decimalValue,
            date: Date(timeIntervalSince1970: TimeInterval(transaction.blocktime ?? UInt64(Date().timeIntervalSince1970))),
            isIncoming: isIncoming,
            transactionParams: nil
        )
    }

    func calculateFee(value: Decimal, size: Int) -> Decimal {
        let perKbDecimalValue = (value * decimalValue).rounded(scale: decimalCount, roundingMode: .up)
        let decimalFeeValue = Decimal(size) / Constants.perKbRate * perKbDecimalValue
        let feeDecimalValue = (decimalFeeValue / decimalValue).rounded(scale: decimalCount, roundingMode: .up)
        return feeDecimalValue
    }
}

extension Fact0rnNetworkProvider {
    enum ProviderError: LocalizedError {
        case failedScriptHashForAddress
    }

    enum Constants {
        static let minimalFeeBlockAmount = 8
        static let normalFeeBlockAmount = 4
        static let priorityFeeBlockAmount = 1

        /// We use 1000, because Electrum node return fee for per 1000 bytes.
        static let perKbRate: Decimal = 1000
    }
}
