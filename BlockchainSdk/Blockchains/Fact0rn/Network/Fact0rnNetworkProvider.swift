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

    // MARK: - Init

    init(provider: ElectrumWebSocketProvider, decimalValue: Decimal) {
        self.provider = provider
    }

    // MARK: - BitcoinNetworkProvider Implementation

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, any Error> {
        guard let scriptHash = try? Fact0rnAddressService.addressToScriptHash(address: address) else {
            return .anyFail(error: ProviderError.failedScriptHashForAddress)
        }

        let addressInfoPublisher = getAddressInfo(identifier: .scriptHash(scriptHash))

        return addressInfoPublisher
            .withWeakCaptureOf(self)
            .tryMap { service, accountInfo in
                service.mapBitcoinResponse(from: accountInfo, outputScript: scriptHash)
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
        .map { minimal, normal, priority in
            BitcoinFee(
                minimalSatoshiPerByte: minimal,
                normalSatoshiPerByte: normal,
                prioritySatoshiPerByte: priority
            )
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, any Error> {
        Future.async {
            try await self.provider.send(transactionHex: transaction)
        }
        .eraseToAnyPublisher()
    }

    func push(transaction: String) -> AnyPublisher<String, any Error> {
        Future.async {
            try await self.provider.send(transactionHex: transaction)
        }
        .eraseToAnyPublisher()
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
                balance: Decimal(balance.confirmed),
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

    private func estimateFee(confirmations count: Int = 10) -> AnyPublisher<Decimal, Error> {
        Future.async {
            try await self.provider.estimateFee(block: count)
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

    private func mapBitcoinResponse(from accountInfo: ElectrumAddressInfo, outputScript: String) -> BitcoinResponse {
        let hasUnconfirmed = accountInfo.balance != .zero
        let unspentOutputs = mapUnspent(outputs: accountInfo.outputs, outputScript: outputScript)

        return BitcoinResponse(
            balance: accountInfo.balance,
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

    private func createPendingTransactions(
        unspents: [ElectrumUTXO],
        address: String
    ) -> AnyPublisher<[PendingTransaction], Error> {
        return .anyFail(error: WalletError.empty)
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
        static let recommendedFeePer1000Bytes = 1000
    }
}
