//
//  StakeKitTarget.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct StakeKitTarget: Moya.TargetType {
    let apiKey: String
    let target: Target

    enum Target {
        case enabledYields
        case getYield(StakeKitDTO.Yield.Info.Request)
        case getBalances(StakeKitDTO.Balances.Request)

        case enterAction(StakeKitDTO.Actions.Enter.Request)

        case constructTransaction(id: String, body: StakeKitDTO.ConstructTransaction.Request)
        case submitTransaction(id: String, body: StakeKitDTO.SubmitTransaction.Request)
    }

    var baseURL: URL {
        URL(string: "https://api.stakek.it/v1/")!
    }

    var path: String {
        switch target {
        case .enabledYields:
            return "yields/enabled"
        case .getYield(let stakekitDTO):
            return "yields/\(stakekitDTO.integrationId)"
        case .getBalances:
            return "yields/balances/scan"
        case .enterAction:
            return "actions/enter"
        case .constructTransaction(let id, _):
            return "/transactions/\(id)"
        case .submitTransaction(let id, _):
            return "/transactions/\(id)/submit"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getYield, .enabledYields:
            return .get
        case .enterAction, .getBalances, .submitTransaction:
            return .post
        case .constructTransaction:
            return .patch
        }
    }

    var task: Moya.Task {
        switch target {
        case .getYield, .enabledYields:
            return .requestPlain
        case .enterAction(let request):
            return .requestJSONEncodable(request)
        case .getBalances(let request):
            return .requestJSONEncodable(request)
        case .constructTransaction(_, let body):
            return .requestJSONEncodable(body)
        case .submitTransaction(_, let body):
            return .requestJSONEncodable(body)
        }
    }

    var headers: [String: String]? {
        ["X-API-KEY": apiKey]
    }
}
