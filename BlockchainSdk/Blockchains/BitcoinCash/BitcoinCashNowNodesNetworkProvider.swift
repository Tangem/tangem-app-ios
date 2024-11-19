//
//  BitcoinCashNowNodesNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.02.2024.
//

import Foundation
import Combine

/// Adapter for existing BlockBookUtxoProvider
final class BitcoinCashNowNodesNetworkProvider: BitcoinNetworkProvider {
    private let blockBookUtxoProvider: BlockBookUtxoProvider
    private let bitcoinCashAddressService: BitcoinCashAddressService

    init(blockBookUtxoProvider: BlockBookUtxoProvider, bitcoinCashAddressService: BitcoinCashAddressService) {
        self.blockBookUtxoProvider = blockBookUtxoProvider
        self.bitcoinCashAddressService = bitcoinCashAddressService
    }

    var host: String {
        blockBookUtxoProvider.host
    }

    var supportsTransactionPush: Bool {
        blockBookUtxoProvider.supportsTransactionPush
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        blockBookUtxoProvider.getInfo(address: addAddressPrefixIfNeeded(address))
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        blockBookUtxoProvider.executeRequest(
            .fees(NodeRequest.estimateFeeRequest(method: "estimatefee")),
            responseType: NodeEstimateFeeResponse.self
        )
        .tryMap { [weak self] response in
            guard let self else {
                throw WalletError.empty
            }

            return try blockBookUtxoProvider.convertFeeRate(response.result)
        }.map { fee in
            // fee for BCH is constant
            BitcoinFee(minimalSatoshiPerByte: fee, normalSatoshiPerByte: fee, prioritySatoshiPerByte: fee)
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUtxoProvider.executeRequest(
            .sendNode(NodeRequest.sendRequest(signedTransaction: transaction)),
            responseType: SendResponse.self
        )
        .map { $0.result }
        .eraseToAnyPublisher()
    }

    func push(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUtxoProvider.push(transaction: transaction)
    }

    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        blockBookUtxoProvider.getSignatureCount(address: address)
    }

    private func addAddressPrefixIfNeeded(_ address: String) -> String {
        if bitcoinCashAddressService.isLegacy(address) {
            return address
        } else {
            let prefix = "bitcoincash:"
            return address.hasPrefix(prefix) ? address : prefix + address
        }
    }
}
