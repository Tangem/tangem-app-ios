//
//  EthereumOptimisticRollupWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// Used by Optimism, Base, and other Ethereum L2s with optimistic rollups.
final class EthereumOptimisticRollupWalletManager: EthereumWalletManager {
    /// We are override this method to combine the two fee's layers in the `Optimistic-Ethereum` network.
    /// Read more:
    /// https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    /// https://help.optimism.io/hc/en-us/articles/4411895794715-How-do-transaction-fees-on-Optimism-work
    /// Short information:
    /// `L2` - Used to provide this transaction in the `Optimistic-etherium` network like a usual tx.
    /// `L1` - Used to processing a transaction in the `Etherium` network  for "safety".
    /// This L1 fee will be added to the transaction fee automatically after it is sent to the network.
    /// This L1 fee calculated the Optimism smart-contract oracle.
    /// This L1 fee have to used ONLY for showing to a user.
    /// When we're building transaction we have to used `gasLimit`, `gasPrice` or `baseFee` ONLY from `L2`
    override func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        do {
            let destination = try addressConverter.convertToETHAddress(destination)

            return super.getFee(destination: destination, value: value, data: data)
                .withWeakCaptureOf(self)
                .flatMap { walletManager, layer2Fees -> AnyPublisher<([Fee], Decimal), Error> in
                    // We use EthereumFeeParameters without increase
                    guard let fee = layer2Fees.first else {
                        return .anyFail(error: BlockchainSdkError.failedToLoadFee)
                    }

                    return walletManager
                        .getLayer1Fee(destination: destination, value: value, data: data, fee: fee)
                        .map { (layer2Fees, $0) }
                        .eraseToAnyPublisher()
                }
                .map { layer2Fees, layer1Fee -> [Fee] in
                    layer2Fees.map { fee in
                        let newAmount = Amount(with: fee.amount, value: fee.amount.value + layer1Fee)
                        let newFee = Fee(newAmount, parameters: fee.parameters)
                        return newFee
                    }
                }
                .eraseToAnyPublisher()
        }
        catch {
            return .anyFail(error: error)
        }
    }
}

// MARK: - Private

private extension EthereumOptimisticRollupWalletManager {
    func getLayer1Fee(
        destination: String,
        value: String?,
        data: Data?,
        fee: Fee
    ) -> AnyPublisher<Decimal, Error> {
        do {
            let hexTransactionData = try txBuilder.buildDummyTransactionForL1(destination: destination, value: value, data: data, fee: fee)
            return networkService
                .read(target: EthereumOptimisticRollupSmartContract.getL1Fee(data: hexTransactionData))
                .withWeakCaptureOf(self)
                .tryMap { walletManager, response in
                    guard let value = EthereumUtils.parseEthereumDecimal(response, decimalsCount: walletManager.wallet.blockchain.decimalCount) else {
                        throw BlockchainSdkError.failedToLoadFee
                    }

                    return value
                }
                // We can ignore errors so as not to block users
                // This L1Fee value is only needed to inform users. It will not used in the transaction
                // Unfortunately L1 fee doesn't work well
                .replaceError(with: 0)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
}
