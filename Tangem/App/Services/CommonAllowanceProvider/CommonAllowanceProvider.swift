//
//  CommonAllowanceProvider.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

class CommonExpressAllowanceProvider {
    private var ethereumNetworkProvider: EthereumNetworkProvider?
    private var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?
    private let logger: Logger

    private var spendersAwaitingApprove = Set<String>()

    init(logger: Logger) {
        self.logger = logger
    }
}

// MARK: - ExpressAllowanceProvider

extension CommonExpressAllowanceProvider: ExpressAllowanceProvider {
    func setup(wallet: WalletModel) {
        ethereumNetworkProvider = wallet.ethereumNetworkProvider
        ethereumTransactionDataBuilder = wallet.ethereumTransactionDataBuilder
    }

    func didSendApproveTransaction(for spender: String) {
        spendersAwaitingApprove.insert(spender)
    }

    func isPermissionRequired(request: ExpressManagerSwappingPairRequest, for spender: String) async throws -> Bool {
        let contractAddress = request.pair.source.expressCurrency.contractAddress
        if contractAddress == ExpressConstants.coinContractAddress {
            return false
        }

        assert(contractAddress != ExpressConstants.coinContractAddress)

        let allowanceWEI = try await getAllowance(
            owner: request.pair.source.defaultAddress,
            to: spender,
            contract: contractAddress
        )

        let allowance = request.pair.source.convertFromWEI(value: allowanceWEI)
        logger.debug("\(request.pair.source) allowance - \(allowance)")

        let approveTxWasSent = spendersAwaitingApprove.contains(spender)
        let isPermissionRequired = allowance < request.amount
        if approveTxWasSent {
            if isPermissionRequired {
                throw AllowanceProviderError.approveTransactionInProgress
            }

            spendersAwaitingApprove.remove(spender)
            return isPermissionRequired
        }

        return isPermissionRequired
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
        guard let ethereumTransactionDataBuilder else {
            throw AllowanceProviderError.ethereumTransactionProcessorNotFound
        }

        return ethereumTransactionDataBuilder.buildForApprove(spender: spender, amount: amount)
    }
}
