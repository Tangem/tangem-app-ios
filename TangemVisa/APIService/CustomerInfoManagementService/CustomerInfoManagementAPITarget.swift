//
//  CustomerInfoManagementAPITarget.swift
//  TangemApp
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CustomerInfoManagementAPITarget: TargetType {
    let authorizationToken: String
    let target: Target

    var baseURL: URL {
        URL(string: "https://api-s.tangem.org/")!
    }

    var path: String {
        switch target {
        case .getCustomerInfo(let customerId):
            return "cim/api/v1/customers/\(customerId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo: return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getCustomerInfo:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        [
            VisaConstants.authorizationHeaderKey: authorizationToken,
            "Content-Type": "application/json",
        ]
    }
}

extension CustomerInfoManagementAPITarget {
    enum Target {
        case getCustomerInfo(customerId: String)
    }
}
