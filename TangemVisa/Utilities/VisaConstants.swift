//
//  VisaConstants.swift
//  TangemVisa
//
//  Created by Andrew Son on 16.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum VisaConstants {
    static let authorizationHeaderKey = "Authorization"
    static let authorizationHeaderValuePrefix = "Bearer "
    static let bffBaseURL: URL = .init(string: "https://api-s.tangem.org/")!
    static let accessTokenKey = "access_token"
    static var defaultHeaderParams: [String: String] {
        let deviceInfo = DeviceInfo()
        return [
            "platform": deviceInfo.platform,
            "version": deviceInfo.version,
        ]
    }
}
