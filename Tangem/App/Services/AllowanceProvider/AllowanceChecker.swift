//
//  AllowanceChecker.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AllowanceChecker {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func isPermissionRequired(amount: Decimal, spender: String) async throws -> Bool {
        guard let contract = walletModel.tokenItem.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        var allowance = try await getAllowance(owner: walletModel.defaultAddress, to: spender, contract: contract)
        allowance /= walletModel.tokenItem.decimalValue
        AppLog.info("\(walletModel.tokenItem.name) allowance - \(allowance)")

        // If we don't have enough allowance
        guard allowance < amount else {
            return false
        }

        return true
    }

    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        guard let ethereumNetworkProvider = walletModel.ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        let allowance = try await ethereumNetworkProvider
            .getAllowance(owner: owner, spender: spender, contractAddress: contract)
            .async()

        return allowance
    }

    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        guard let ethereumTransactionDataBuilder = walletModel.ethereumTransactionDataBuilder else {
            throw AllowanceCheckerError.ethereumTransactionDataBuilderNotFound
        }

        guard let ethereumNetworkProvider = walletModel.ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        guard let contract = walletModel.tokenItem.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let approveAmount: Decimal = {
            switch policy {
            case .specified: amount * walletModel.tokenItem.decimalValue
            case .unlimited: .greatestFiniteMagnitude
            }
        }()

        let data = try ethereumTransactionDataBuilder.buildForApprove(spender: spender, amount: approveAmount)
        let amount = BSDKAmount(
            with: walletModel.feeTokenItem.blockchain,
            type: walletModel.feeTokenItem.amountType,
            value: 0
        )

        let fee = try await ethereumNetworkProvider
            .getFee(destination: contract, value: amount.encodedForSend, data: data)
            .async()

        // Use fastest
        guard let fee = fee[safe: 2] else {
            throw AllowanceCheckerError.approveFeeNotFound
        }

        return .init(txData: data, spender: spender, toContractAddress: contract, fee: fee)
    }
}

enum AllowanceCheckerError: String, Hashable, LocalizedError {
    case contractAddressNotFound
    case ethereumNetworkProviderNotFound
    case ethereumTransactionDataBuilderNotFound
    case approveFeeNotFound
}
