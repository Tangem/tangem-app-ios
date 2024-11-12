//
//  CommonExpressFeeProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk
import BigInt

class CommonExpressFeeProvider {
    var wallet: WalletModel

    init(wallet: WalletModel) {
        self.wallet = wallet
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeProvider: ExpressFeeProvider {
    func setup(wallet: WalletModel) {
        self.wallet = wallet
    }

    func estimatedFee(amount: Decimal) async throws -> ExpressFee {
        let amount = makeAmount(amount: amount, item: wallet.tokenItem)
        let fees = try await wallet.estimatedFee(amount: amount).async()
        return try mapToExpressFee(fees: fees)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        guard let ethereumNetworkProvider = wallet.ethereumNetworkProvider else {
            throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
        }

        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(estimatedGasLimit),
            supportsEIP1559: wallet.tokenItem.blockchain.supportsEIP1559
        )

        let amount = parameters.calculateFee(decimalValue: wallet.feeTokenItem.decimalValue)
        return Fee(makeAmount(amount: amount, item: wallet.tokenItem))
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee {
        switch amount {
        case .transfer(let amount):
            let amount = makeAmount(amount: amount, item: wallet.tokenItem)
            let fees = try await wallet.getFee(amount: amount, destination: destination).async()
            return try mapToExpressFee(fees: fees)

        case .dex(let txValue, let txData):
            // For DEX have to use `txData` when calculate fee
            guard let ethereumNetworkProvider = wallet.ethereumNetworkProvider else {
                throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
            }

            let amount = makeAmount(amount: txValue, item: wallet.feeTokenItem)
            var fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: txData
            ).async()

            // For EVM networks increase gas limit
            fees = fees.map { increaseGasLimit(fee: $0) }

            return try mapToExpressFee(fees: fees)
        }
    }
}

// MARK: - Private

private extension CommonExpressFeeProvider {
    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
        Amount(with: item.blockchain, type: item.amountType, value: amount)
    }

    func mapToExpressFee(fees: [Fee]) throws -> ExpressFee {
        switch fees.count {
        case 1:
            return .single(fees[0])
        case 3 where wallet.tokenItem.blockchain.isUTXO:
            return .single(fees[1])
        case 3:
            return .double(market: fees[1], fast: fees[2])
        default:
            throw ExpressFeeProviderError.feeNotFound
        }
    }

    func increaseGasLimit(fee: Fee) -> Fee {
        guard let parameters = fee.parameters as? EthereumFeeParameters else {
            return fee
        }

        let gasLimit = parameters.gasLimit * BigUInt(112) / BigUInt(100)
        let newParameters = parameters.changingGasLimit(to: gasLimit)
        let feeValue = newParameters.calculateFee(decimalValue: wallet.feeTokenItem.decimalValue)
        let amount = Amount(with: wallet.feeTokenItem.blockchain, type: wallet.feeTokenItem.amountType, value: feeValue)
        return Fee(amount, parameters: newParameters)
    }
}

enum ExpressFeeProviderError: Error {
    case feeNotFound
    case ethereumNetworkProviderNotFound
}
