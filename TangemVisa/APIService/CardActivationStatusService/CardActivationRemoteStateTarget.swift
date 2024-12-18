//
//  CardActivationRemoteStateTarget.swift
//  TangemVisa
//
//  Created by Andrew Son on 16.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CardActivationRemoteStateTarget: TargetType {
    let target: Target
    let authorizationToken: String

    var baseURL: URL { URL(string: "https://bff.tangem.com")! }

    var path: String {
        switch target {
        case .activationStatus:
            return "activation-status"
        }
    }

    var method: Moya.Method {
        switch target {
        case .activationStatus:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .activationStatus:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        [
            VisaConstants.authorizationHeaderKey: authorizationToken,
        ]
    }
}

extension CardActivationRemoteStateTarget {
    enum Target {
        case activationStatus
    }
}
