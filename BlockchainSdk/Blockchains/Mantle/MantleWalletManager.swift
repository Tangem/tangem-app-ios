//
//  MantleWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 15.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine
import TangemFoundation

// This is a workaround for sending a Mantle transaction.
// Unfortunately, Mantle's current implementation does not conform to our existing fee calculation rules.
// https://tangem.slack.com/archives/GMXC6PP71/p1719591856597299?thread_ts=1714215815.690169&cid=GMXC6PP71
final class MantleWalletManager: EthereumWalletManager {
    override func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], any Error> {
        super.getFee(
            destination: destination,
            value: prepareAdjustedValue(value: value),
            data: data
        )
        .withWeakCaptureOf(self)
        .tryMap { walletManager, fees in
            try fees.map { fee in
                try walletManager.mapMantleFee(fee, gasLimitMultiplier: MantleUtils.feeGasLimitMultiplier)
            }
        }
        .eraseToAnyPublisher()
    }

    override func sign(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<String, any Error> {
        var transaction = transaction
        do {
            transaction.fee = try mapMantleFee(transaction.fee, gasLimitMultiplier: MantleUtils.signGasLimitMultiplier)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return super.sign(transaction, signer: signer)
    }

    override func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, any Error> {
        super.getGasLimit(to: to, from: from, value: value, data: data)
            .map { gasLimit in
                MantleUtils.multiplyGasLimit(gasLimit, with: MantleUtils.feeGasLimitMultiplier)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension MantleWalletManager {
    func mapMantleFee(_ fee: Fee, gasLimitMultiplier: Double) throws -> Fee {
        let parameters: any EthereumFeeParameters = switch fee.parameters {
        case let parameters as EthereumEIP1559FeeParameters:
            EthereumEIP1559FeeParameters(
                gasLimit: MantleUtils.multiplyGasLimit(parameters.gasLimit, with: gasLimitMultiplier),
                maxFeePerGas: parameters.maxFeePerGas,
                priorityFee: parameters.priorityFee
            )
        case let parameters as EthereumLegacyFeeParameters:
            EthereumLegacyFeeParameters(
                gasLimit: MantleUtils.multiplyGasLimit(parameters.gasLimit, with: gasLimitMultiplier),
                gasPrice: parameters.gasPrice
            )
        default:
            throw WalletError.failedToGetFee
        }

        let blockchain = wallet.blockchain
        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let amount = Amount(with: blockchain, value: feeValue)

        return Fee(amount, parameters: parameters)
    }

    func prepareAdjustedValue(value: String?) -> String? {
        guard let value, let currentBalance = wallet.amounts[.coin]?.value else {
            return nil
        }

        let parsedValue = EthereumUtils.parseEthereumDecimal(
            value,
            decimalsCount: wallet.blockchain.decimalCount
        )

        guard let parsedValue else {
            return nil
        }

        let blockchain = wallet.blockchain
        let delta = blockchain.minimumValue

        let shouldSubtractPenny = currentBalance.isEqual(to: parsedValue, delta: delta)
        let valueToSubtract = shouldSubtractPenny ? delta : 0

        return Amount(
            with: blockchain,
            type: .coin,
            value: parsedValue - valueToSubtract
        )
        .encodedForSend
    }
}
