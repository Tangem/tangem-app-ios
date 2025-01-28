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

    // MARK: - Init

    init(provider: ElectrumWebSocketProvider, decimalValue: Decimal) {
        self.provider = provider
        self.decimalValue = decimalValue
    }

    // MARK: - BitcoinNetworkProvider Implementation

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, any Error> {
        return Result { try Fact0rnAddressService.addressToScriptHash(address: address) }
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { provider, scriptHash in
                provider.getAddressInfo(identifier: .scriptHash(scriptHash))
            }
            .withWeakCaptureOf(self)
            .tryMap { provider, accountInfo in
                let outputScriptData = try Fact0rnAddressService.addressToScript(address: address).scriptData

                return try provider.mapBitcoinResponse(
                    account: accountInfo,
                    outputScript: outputScriptData.hexString
                )
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, any Error> {
        let minimalEstimateFeePublisher = estimateFee(confirmation: Constants.minimalFeeBlockAmount)
        let normalEstimateFeePublisher = estimateFee(confirmation: Constants.normalFeeBlockAmount)
        let priorityEstimateFeePublisher = estimateFee(confirmation: Constants.priorityFeeBlockAmount)

        return Publishers.Zip3(
            minimalEstimateFeePublisher,
            normalEstimateFeePublisher,
            priorityEstimateFeePublisher
        )
        .withWeakCaptureOf(self)
        .map { provider, values in
            let minimalSatoshiPerByte = values.0 / Constants.perKbRate
            let normalSatoshiPerByte = values.1 / Constants.perKbRate
            let prioritySatoshiPerByte = values.2 / Constants.perKbRate

            return (minimalSatoshiPerByte, normalSatoshiPerByte, prioritySatoshiPerByte)
        }
        .withWeakCaptureOf(self)
        .map { provider, values in
            return BitcoinFee(
                minimalSatoshiPerByte: values.0,
                normalSatoshiPerByte: values.1,
                prioritySatoshiPerByte: values.2
            )
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, any Error> {
        Future.async {
            return try await self.provider.send(transactionHex: transaction)
        }
        .eraseToAnyPublisher()
    }

    func push(transaction: String) -> AnyPublisher<String, any Error> {
        assertionFailure("This method marked as deprecated")
        return .anyFail(error: BlockchainSdkError.noAPIInfo)
    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, any Error> {
        Future.async {
            let txHistory = try await self.provider.getTxHistory(identifier: .scriptHash(address))
            return txHistory.count
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func getAddressInfo(identifier: ElectrumWebSocketProvider.Identifier) -> AnyPublisher<ElectrumAddressInfo, Error> {
        Future.async {
            async let balance = self.provider.getBalance(identifier: identifier)
            async let unspents = self.provider.getUnspents(identifier: identifier)

            return try await ElectrumAddressInfo(
                balance: Decimal(balance.confirmed) / self.decimalValue,
                unconfirmed: Decimal(balance.unconfirmed) / self.decimalValue,
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

    private func estimateFee(confirmation blocks: Int) -> AnyPublisher<Decimal, Error> {
        Future.async {
            try await self.provider.estimateFee(block: blocks)
        }
        .eraseToAnyPublisher()
    }

    private func send(transactionHex: String) -> AnyPublisher<String, Error> {
        Future.async {
            try await self.provider.send(transactionHex: transactionHex)
        }
        .eraseToAnyPublisher()
    }

    private func getTransactionInfo(hash: String) -> AnyPublisher<ElectrumDTO.Response.Transaction, Error> {
        Future.async {
            try await self.provider.getTransaction(hash: hash)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func mapBitcoinResponse(account: ElectrumAddressInfo, outputScript: String) throws -> BitcoinResponse {
        let hasUnconfirmed = account.unconfirmed != .zero
        let unspentOutputs = mapUnspent(outputs: account.outputs, outputScript: outputScript)

        return BitcoinResponse(
            balance: account.balance,
            hasUnconfirmed: hasUnconfirmed,
            pendingTxRefs: [],
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
