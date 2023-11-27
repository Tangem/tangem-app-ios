//
//  CommonAllowanceProvider.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

class CommonExpressAllowanceProvider {
    private var ethereumNetworkProvider: EthereumNetworkProvider?
    private var ethereumTransactionProcessor: EthereumTransactionProcessor?

    init() {}
}

// MARK: - AllowanceProvider

extension CommonExpressAllowanceProvider: ExpressAllowanceProvider {
    func setup(wallet: WalletModel) {
        ethereumNetworkProvider = wallet.ethereumNetworkProvider
        ethereumTransactionProcessor = wallet.ethereumTransactionProcessor
    }

    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        guard let ethereumNetworkProvider else {
            throw AllowanceProviderError.ethereumNetworkProviderNotFound
        }

        let allowance = try await ethereumNetworkProvider.getAllowance(
            owner: owner,
            spender: spender,
            contractAddress: contract
        ).async()

        return allowance
    }

    func makeApproveData(spender: String, amount: Decimal) throws -> Data {
        guard let ethereumTransactionProcessor else {
            throw AllowanceProviderError.ethereumTransactionProcessorNotFound
        }

        return ethereumTransactionProcessor.buildForApprove(spender: spender, amount: amount)
    }
}

enum AllowanceProviderError: LocalizedError {
    case ethereumNetworkProviderNotFound
    case ethereumTransactionProcessorNotFound
}
