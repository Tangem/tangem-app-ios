//
//  BlockBookUTXOProvider.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Documentation: https://github.com/trezor/blockbook/blob/master/docs/api.md
class BlockBookUTXOProvider {
    var host: String {
        "\(blockchain.currencySymbol.lowercased()).\(config.host)"
    }

    private let blockchain: Blockchain
    private let config: BlockBookConfig
    private let provider: NetworkProvider<BlockBookTarget>

    let addressPrefixProvider: AddressPrefixProvider?

    var decimalValue: Decimal {
        blockchain.decimalValue
    }

    init(
        blockchain: Blockchain,
        blockBookConfig: BlockBookConfig,
        addressPrefixProvider: AddressPrefixProvider? = nil,
        networkConfiguration: NetworkProviderConfiguration
    ) {
        self.blockchain = blockchain
        config = blockBookConfig
        self.addressPrefixProvider = addressPrefixProvider
        provider = NetworkProvider<BlockBookTarget>(configuration: networkConfiguration)
    }

    func addressData(
        address: String,
        parameters: BlockBookTarget.AddressRequestParameters
    ) -> AnyPublisher<BlockBookAddressResponse, Error> {
        executeRequest(.address(address: addAddressPrefixIfNeeded(address), parameters: parameters))
    }

    func unspentTxData(address: String) -> AnyPublisher<[BlockBookUnspentTxResponse], Error> {
        executeRequest(.utxo(address: addAddressPrefixIfNeeded(address)))
    }

    func getFeeRatePerByte(for confirmationBlocks: Int) -> AnyPublisher<Decimal, Error> {
        executeRequest(
            .fees(NodeRequest.estimateFeeRequest(confirmationBlocks: confirmationBlocks)),
            responseType: BlockBookFeeResponse.self
        )
        .tryMap { [weak self] response in
            guard let self else {
                throw WalletError.empty
            }
            return try convertFeeRate(Decimal(response.result.feerate))
        }.eraseToAnyPublisher()
    }

    func sendTransaction(hex: String) -> AnyPublisher<String, Error> {
        guard let transactionData = hex.data(using: .utf8) else {
            return .anyFail(error: WalletError.failedToSendTx)
        }

        return executeRequest(
            .sendBlockBook(tx: transactionData),
            responseType: SendResponse.self
        )
        .map { $0.result }
        .eraseToAnyPublisher()
    }

    func mapBitcoinFee(
        _ feeRatePublishers: [AnyPublisher<Decimal, Error>]
    ) -> AnyPublisher<BitcoinFee, Error> {
        Publishers.MergeMany(feeRatePublishers)
            .collect()
            .map { $0.sorted() }
            .tryMap { fees -> BitcoinFee in
                guard fees.count == feeRatePublishers.count else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return BitcoinFee(
                    minimalSatoshiPerByte: fees[0],
                    normalSatoshiPerByte: fees[1],
                    prioritySatoshiPerByte: fees[2]
                )
            }
            .eraseToAnyPublisher()
    }

    func convertFeeRate(_ fee: Decimal) throws -> Decimal {
        if fee <= 0 {
            throw BlockchainSdkError.failedToLoadFee
        }

        // estimatesmartfee returns fee in currency per kilobyte
        let bytesInKiloByte: Decimal = 1024
        let feeRatePerByte = fee * decimalValue / bytesInKiloByte

        return feeRatePerByte.rounded(roundingMode: .up)
    }

    func executeRequest<T: Decodable>(_ request: BlockBookTarget.Request) -> AnyPublisher<T, Error> {
        provider
            .requestPublisher(target(for: request))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .eraseError()
            .eraseToAnyPublisher()
    }

    func executeRequest<T: Decodable>(
        _ request: BlockBookTarget.Request,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        executeRequest(request)
    }

    private func target(for request: BlockBookTarget.Request) -> BlockBookTarget {
        BlockBookTarget(request: request, config: config, blockchain: blockchain)
    }

    private func addAddressPrefixIfNeeded(_ address: String) -> String {
        addressPrefixProvider.flatMap { $0.addPrefixIfNeeded(address) } ?? address
    }
}
