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
        let amount = makeAmount(amount: amount)
        var fees = try await wallet.estimatedFee(amount: amount).async()

        // For EVM networks we've decided increase gas limit for estimatedFee just in case
        fees = fees.map { fee in
            guard let parameters = fee.parameters as? EthereumEIP1559FeeParameters else {
                return fee
            }

            let gasLimit = parameters.gasLimit * BigUInt(112) / BigUInt(100)
            let feeParameters = EthereumEIP1559FeeParameters(
                gasLimit: gasLimit,
                maxFeePerGas: parameters.maxFeePerGas,
                priorityFee: parameters.priorityFee
            )
            let feeValue = feeParameters.caclulateFee(decimalValue: wallet.tokenItem.blockchain.decimalValue)
            let amount = Amount(with: wallet.tokenItem.blockchain, value: feeValue)
            return Fee(amount, parameters: feeParameters)
        }

        return try mapToExpressFee(fees: fees)
    }

    func getFee(amount: Decimal, destination: String, hexData: Data?) async throws -> ExpressFee {
        let amount = makeAmount(amount: amount)

        // If EVM network we should pass data in the fee calculation
        if let ethereumNetworkProvider = wallet.ethereumNetworkProvider, let hexData {
            let fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: hexData
            ).async()

            return try mapToExpressFee(fees: fees)
        }

        let fees = try await wallet.getFee(amount: amount, destination: destination).async()
        return try mapToExpressFee(fees: fees)
    }
}

// MARK: - Private

private extension CommonExpressFeeProvider {
    func makeAmount(amount: Decimal) -> Amount {
        Amount(
            with: wallet.blockchainNetwork.blockchain,
            type: wallet.amountType,
            value: amount
        )
    }

    func mapToExpressFee(fees: [Fee]) throws -> ExpressFee {
        switch fees.count {
        case 1:
            return .single(fees[0])
        case 3:
            return .double(market: fees[1], fast: fees[2])
        default:
            throw ExpressFeeProviderError.feeNotFound
        }
    }
}

enum ExpressFeeProviderError: Error {
    case feeNotFound
}
