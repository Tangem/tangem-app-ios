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

    func balances(wallet: StakingWallet) async throws -> [StakingBalanceInfo] {
        let request = StakeKitDTO.Balances.Request(addresses: .init(address: wallet.address), network: wallet.item.network)
        let response = try await service.getBalances(request: request)
        let balancesInfo = try mapper.mapToBalanceInfo(from: response)
        return balancesInfo
    }

    func estimateStakeFee(params: StakingActionRequestParams) async throws -> Decimal {
        let request = StakeKitDTO.EstimateGas.Enter.Request(
            integrationId: params.integrationId,
            addresses: .init(
                address: params.address,
                additionalAddresses: params.additionalAddresses.flatMap {
                    StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
                }
            ),
            args: .init(
                amount: params.amount.description,
                validatorAddress: params.validator,
                inputToken: params.token.flatMap {
                    mapper.mapToTokenDTO(from: $0)
                }
            )
        )

        let response = try await service.estimateGasEnterAction(request: request)
        guard let result = Decimal(stringValue: response.amount) else {
            throw StakeKitMapperError.noData("EnterAction fee not found")
        }
        return result
    }

    func estimateUnstakeFee(params: StakingActionRequestParams) async throws -> Decimal {
        let request = StakeKitDTO.EstimateGas.Exit.Request(
            integrationId: params.integrationId,
            addresses: .init(
                address: params.address,
                additionalAddresses: params.additionalAddresses.flatMap {
                    StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
                }
            ),
            args: .init(
                amount: params.amount.description,
                validatorAddress: params.validator,
                inputToken: params.token.flatMap {
                    mapper.mapToTokenDTO(from: $0)
                }
            )
        )

        let response = try await service.estimateGasExitAction(request: request)
        guard let result = Decimal(stringValue: response.amount) else {
            throw StakeKitMapperError.noData("ExitAction fee not found")
        }
        return result
    }

    func estimateClaimRewardsFee(
        params: StakingActionRequestParams,
        passthrough: String
    ) async throws -> Decimal {
        let request = StakeKitDTO.EstimateGas.Pending.Request(
            type: .claimRewards,
            integrationId: params.integrationId,
            passthrough: passthrough,
            addresses: .init(
                address: params.address,
                additionalAddresses: params.additionalAddresses.flatMap {
                    StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
                }
            ),
            args: .init(
                amount: params.amount.description,
                validatorAddress: params.validator,
                inputToken: params.token.flatMap {
                    mapper.mapToTokenDTO(from: $0)
                }
            )
        )

        let response = try await service.estimateGasPendingAction(request: request)
        guard let result = Decimal(stringValue: response.amount) else {
            throw StakeKitMapperError.noData("PendingAction fee not found")
        }
        return result
    }

    func enterAction(params: StakingActionRequestParams) async throws -> EnterAction {
        let request = StakeKitDTO.Actions.Enter.Request(
            integrationId: params.integrationId,
            addresses: .init(
                address: params.address,
                additionalAddresses: params.additionalAddresses.flatMap {
                    StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
                }
            ),
            args: .init(
                amount: params.amount.description,
                validatorAddress: params.validator,
                inputToken: params.token.flatMap {
                    mapper.mapToTokenDTO(from: $0)
                }
            )
        )

        let response = try await service.enterAction(request: request)
        let enterAction = try mapper.mapToEnterAction(from: response)
        return enterAction
    }

    func exitAction(params: StakingActionRequestParams) async throws -> ExitAction {
        let request = StakeKitDTO.Actions.Exit.Request(
            integrationId: params.integrationId,
            addresses: .init(
                address: params.address,
                additionalAddresses: params.additionalAddresses.flatMap {
                    StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
                }
            ),
            args: .init(
                amount: params.amount.description,
                validatorAddress: params.validator,
                inputToken: params.token.flatMap {
                    mapper.mapToTokenDTO(from: $0)
                }
            )
        )

        let response = try await service.exitAction(request: request)
        let enterAction = try mapper.mapToExitAction(from: response)
        return enterAction
    }

    func pendingAction() async throws {
        // TODO: https://tangem.atlassian.net/browse/IOS-7482
    }

    func transaction(id: String) async throws -> StakingTransactionInfo {
        let response = try await service.transaction(id: id)
        let transactionInfo = try mapper.mapToTransactionInfo(from: response)
        return transactionInfo
    }

    func patchTransaction(id: String) async throws -> StakingTransactionInfo {
        let response = try await service.constructTransaction(id: id, request: .init(gasArgs: .none))
        let transactionInfo = try mapper.mapToTransactionInfo(from: response)
        return transactionInfo
    }

    func submitTransaction(hash: String, signedTransaction: String) async throws {
        _ = try await service.submitTransaction(id: hash, request: .init(signedTransaction: signedTransaction))
    }

    func submitHash(hash: String, transactionId: String) async throws {
        try await service.submitHash(id: transactionId, request: .init(hash: hash))
    }
}
