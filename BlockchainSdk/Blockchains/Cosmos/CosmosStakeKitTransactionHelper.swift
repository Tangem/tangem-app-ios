//
//  CosmosStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 16.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct CosmosStakeKitTransactionHelper {
    private let builder: CosmosTransactionBuilder

    init(builder: CosmosTransactionBuilder) {
        self.builder = builder
    }

    func prepareForSign(stakingTransaction: StakeKitTransaction) throws -> Data {
        let txInputData = try makeInput(stakingTransaction: stakingTransaction)
        return try builder.buildForSignRaw(txInputData: txInputData)
    }

    func buildForSend(
        stakingTransaction: StakeKitTransaction,
        signature: Data
    ) throws -> Data {
        let txInputData = try makeInput(stakingTransaction: stakingTransaction)
        return try builder.buildForSendRaw(txInputData: txInputData, signature: signature)
    }

    private func makeInput(
        stakingTransaction: StakeKitTransaction
    ) throws -> Data {
        let stakingProtoMessage = try CosmosProtoMessage(serializedData: Data(hex: stakingTransaction.unsignedData))

        let feeMessage = stakingProtoMessage.feeAndKeyContainer.feeContainer
        let feeValue = feeMessage.feeAmount

        guard let message = CosmosMessage.createStakeMessage(message: stakingProtoMessage.delegateContainer.delegate) else {
            throw WalletError.failedToBuildTx
        }

        let serializedInput = try builder.serializeInput(
            gas: feeMessage.gas,
            feeAmount: feeValue.amount,
            feeDenomiation: feeValue.denomination,
            messages: [message],
            memo: nil
        )

        return serializedInput
    }
}
