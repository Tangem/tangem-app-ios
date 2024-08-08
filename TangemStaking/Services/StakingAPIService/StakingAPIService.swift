//
//  StakingAPIService.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol StakingAPIService {
    func enabledYields() async throws -> StakeKitDTO.Yield.Enabled.Response
    func getYield(request: StakeKitDTO.Yield.Info.Request) async throws -> StakeKitDTO.Yield.Info.Response
    func getBalances(request: StakeKitDTO.Balances.Request) async throws -> [StakeKitDTO.Balances.Response]

    func estimateGasEnterAction(request: StakeKitDTO.EstimateGas.EnterAction.Request) async throws -> StakeKitDTO.EstimateGas.EnterAction.Response
    func estimateGasExitAction(request: StakeKitDTO.EstimateGas.ExitAction.Request) async throws -> StakeKitDTO.EstimateGas.ExitAction.Response
    func estimateGasPendingAction(request: StakeKitDTO.EstimateGas.PendingAction.Request) async throws -> StakeKitDTO.EstimateGas.PendingAction.Response

    func enterAction(request: StakeKitDTO.Actions.Enter.Request) async throws -> StakeKitDTO.Actions.Enter.Response
    func exitAction(request: StakeKitDTO.Actions.Exit.Request) async throws -> StakeKitDTO.Actions.Exit.Response
    func pendingAction(request: StakeKitDTO.Actions.Pending.Request) async throws -> StakeKitDTO.Actions.Pending.Response

    func transaction(id: String) async throws -> StakeKitDTO.Transaction.Response
    func constructTransaction(id: String, request: StakeKitDTO.ConstructTransaction.Request) async throws -> StakeKitDTO.Transaction.Response
    func submitTransaction(id: String, request: StakeKitDTO.SubmitTransaction.Request) async throws -> StakeKitDTO.SubmitTransaction.Response
    func submitHash(id: String, request: StakeKitDTO.SubmitHash.Request) async throws -> StakeKitDTO.SubmitHash.Response
}
