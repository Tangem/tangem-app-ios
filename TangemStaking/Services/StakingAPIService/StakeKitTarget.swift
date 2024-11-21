//
//  StakeKitTarget.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct StakeKitTarget: Moya.TargetType {
    let apiKey: String
    let target: Target

    enum Target {
        case enabledYields
        case getYield(id: String, StakeKitDTO.Yield.Info.Request)
        case getBalances(StakeKitDTO.Balances.Request)

        case enterAction(StakeKitDTO.Actions.Enter.Request)
        case exitAction(StakeKitDTO.Actions.Exit.Request)
        case pendingAction(StakeKitDTO.Actions.Pending.Request)

        case estimateGasEnterAction(StakeKitDTO.EstimateGas.Enter.Request)
        case estimateGasExitAction(StakeKitDTO.EstimateGas.Exit.Request)
        case estimateGasPendingAction(StakeKitDTO.EstimateGas.Pending.Request)

        case transaction(id: String)
        case constructTransaction(id: String, body: StakeKitDTO.ConstructTransaction.Request)
        case submitTransaction(id: String, body: StakeKitDTO.SubmitTransaction.Request)
        case submitHash(id: String, body: StakeKitDTO.SubmitHash.Request)
        case actions(StakeKitDTO.Actions.List.Request)
    }

    var baseURL: URL {
        URL(string: "https://api.stakek.it/v1/")!
    }

    var path: String {
        switch target {
        case .enabledYields:
            return "yields/enabled"
        case .getYield(let id, _):
            return "yields/\(id)"
        case .getBalances:
            return "yields/balances/scan"
        case .estimateGasEnterAction:
            return "actions/enter/estimate-gas"
        case .estimateGasExitAction:
            return "actions/exit/estimate-gas"
        case .estimateGasPendingAction:
            return "actions/pending/estimate-gas"
        case .enterAction:
            return "actions/enter"
        case .exitAction:
            return "actions/exit"
        case .pendingAction:
            return "actions/pending"
        case .constructTransaction(let id, _), .transaction(let id):
            return "transactions/\(id)"
        case .submitTransaction(let id, _):
            return "transactions/\(id)/submit"
        case .submitHash(let id, _):
            return "transactions/\(id)/submit_hash"
        case .actions(let request):
            return "actions"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getYield, .enabledYields, .transaction, .actions:
            return .get
        case .enterAction, .exitAction, .pendingAction, .getBalances, .submitTransaction, .submitHash,
             .estimateGasEnterAction, .estimateGasExitAction, .estimateGasPendingAction:
            return .post
        case .constructTransaction:
            return .patch
        }
    }

    var task: Moya.Task {
        switch target {
        case .enabledYields, .transaction:
            return .requestPlain
        case .getYield(_, let request):
            return .requestParameters(request, encoding: URLEncoding(boolEncoding: .literal))
        case .enterAction(let request):
            return .requestJSONEncodable(request)
        case .pendingAction(let request):
            return .requestJSONEncodable(request)
        case .exitAction(let request):
            return .requestJSONEncodable(request)
        case .getBalances(let request):
            return .requestJSONEncodable(request)
        case .constructTransaction(_, let body):
            return .requestJSONEncodable(body)
        case .submitTransaction(_, let body):
            return .requestJSONEncodable(body)
        case .submitHash(_, let body):
            return .requestJSONEncodable(body)
        case .estimateGasEnterAction(let request):
            return .requestJSONEncodable(request)
        case .estimateGasExitAction(let request):
            return .requestJSONEncodable(request)
        case .estimateGasPendingAction(let request):
            return .requestJSONEncodable(request)
        case .actions(let request):
            return .requestParameters(request, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        ["X-API-KEY": apiKey]
    }
}
