//
//  ExpressAuthorizationPlugin.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya

struct ExpressAuthorizationPlugin: PluginType {
    let apiKey: String
    let userId: String
    let sessionId: String
    let refcode: String?

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        request.headers.add(name: "api-key", value: apiKey)
        request.headers.add(name: "user-id", value: userId)
        request.headers.add(name: "session-id", value: sessionId)

        if let refcode {
            request.headers.add(name: "refcode", value: refcode)
        }

        return request
    }
}
