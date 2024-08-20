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

class CommonAllowanceProvider {
    private var walletModel: WalletModel
    private var spendersAwaitingApprove: Set<String> = []

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - AllowanceProvider

extension CommonAllowanceProvider: AllowanceProvider {
    var isSupportAllowance: Bool {
        walletModel.tokenItem.blockchain.isEvm && walletModel.tokenItem.isToken
    }

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState {
        let checker = AllowanceChecker(walletModel: walletModel)
        let isPermissionRequired = try await checker.isPermissionRequired(amount: amount, spender: spender)

        guard isPermissionRequired else {
            spendersAwaitingApprove.remove(spender)

            return .enoughAllowance
        }

        let approveTxWasSent = spendersAwaitingApprove.contains(spender)
        if approveTxWasSent {
            return .approveTransactionInProgress
        }

        let approveData = try await checker.makeApproveData(spender: spender, amount: amount, policy: approvePolicy)
        return .permissionRequired(approveData)
    }

    func didSendApproveTransaction(for spender: String) {
        spendersAwaitingApprove.insert(spender)
    }
}

// MARK: - ExpressAllowanceProvider

extension CommonAllowanceProvider: ExpressAllowanceProvider {
    func allowanceState(request: ExpressManagerSwappingPairRequest, spender: String, policy: ExpressApprovePolicy) async throws -> AllowanceState {
        let contractAddress = request.pair.source.expressCurrency.contractAddress
        if contractAddress == ExpressConstants.coinContractAddress {
            return .enoughAllowance
        }

        assert(contractAddress != ExpressConstants.coinContractAddress)

        return try await allowanceState(amount: request.amount, spender: spender, approvePolicy: policy)
    }
}

// MARK: - UpdatableAllowanceProvider

extension CommonAllowanceProvider: UpdatableAllowanceProvider {
    func setup(wallet: WalletModel) {
        walletModel = wallet
    }
}
