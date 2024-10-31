//
//  TransactionCreator+.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension TransactionCreator {
    func buildTransaction(tokenItem: TokenItem, feeTokenItem: TokenItem, amount: Decimal, fee: Fee, destination: TransactionCreatorDestination) async throws -> BSDKTransaction {
        switch destination {
        case .send(let string):
            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
            return try await createTransaction(amount: amount, fee: fee, destinationAddress: string)
        case .contractCall(let contract, let data):
            let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: amount)

            var transaction = try await createTransaction(
                amount: amount,
                fee: fee,
                destinationAddress: contract,
                contractAddress: contract
            )

            // In EVM-like blockchains we should add the txData to the transaction
            transaction.params = EthereumTransactionParams(data: data)

            return transaction
        }
    }
}

enum TransactionCreatorDestination {
    case send(destination: String)
    case contractCall(contract: String, data: Data)
}
