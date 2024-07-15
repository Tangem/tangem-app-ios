//
//  CommonStakingAPIProvider.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingAPIProvider: StakingAPIProvider {
    let service: StakingAPIService
    let mapper: StakeKitMapper

    init(service: StakingAPIService, mapper: StakeKitMapper) {
        self.service = service
        self.mapper = mapper
    }

    func enabledYields() async throws -> [YieldInfo] {
        let response = try await service.enabledYields()
        let yieldInfos = try response.data.map(mapper.mapToYieldInfo(from:))
        return yieldInfos
    }

    func yield(integrationId: String) async throws -> YieldInfo {
        let response = try await service.getYield(request: .init(integrationId: integrationId))
        let yieldInfo = try mapper.mapToYieldInfo(from: response)
        return yieldInfo
    }

    func balance(address: String, network: String) async throws -> BalanceInfo {
        let request = StakeKitDTO.Balances.Request(addresses: .init(address: address), network: .init(rawValue: network)!)
        let response = try await service.getBalances(request: request)
        let balanceInfo = try mapper.mapToBalanceInfo(from: response)
        return balanceInfo
    }

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> EnterAction {
        let request = StakeKitDTO.Actions.Enter.Request(
            integrationId: integrationId,
            addresses: .init(address: address),
            args: .init(amount: amount.description, validatorAddress: validator, validatorAddresses: [.init(address: validator)])
        )

        let response = try await service.enterAction(request: request)
        let enterAction = try mapper.mapToEnterAction(from: response)
        return enterAction
    }

    func patchTransaction(id: String) async throws -> TransactionInfo {
        let response = try await service.constructTransaction(id: id, request: .init(gasArgs: .none))
        let transactionInfo = try mapper.mapToTransactionInfo(from: response)
        return transactionInfo
    }

    func submitTransaction(hash: String, signedTransaction: String) async throws {
        let response = try await service.submitTransaction(id: hash, request: .init(signedTransaction: signedTransaction))
    }
}
