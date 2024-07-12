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
        case enterAction(StakeKitDTO.Actions.Enter.Request)
        case submitHash(StakeKitDTO.SubmitHash.Request, transactionId: String)
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
        case .enterAction:
            return "actions/enter"
        case .submitHash(_, let transactionId):
            return "transactions/\(transactionId)/submit_hash"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getYield, .enabledYields:
            return .get
        case .enterAction, .submitHash:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getYield, .enabledYields:
            return .requestPlain
        case .enterAction(let request):
            return .requestJSONEncodable(request)
        case .submitHash(let request, _):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        ["X-API-KEY": apiKey]
    }
}
