//
//  DeviceInfoPlugin.swift
//  TangemNetworkUtils
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct DeviceInfoPlugin: PluginType {
    private let deviceInfo: DeviceInfo

    public init(deviceInfo: DeviceInfo = DeviceInfo()) {
        self.deviceInfo = deviceInfo
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        request.headers.add(name: "version", value: deviceInfo.version)
        request.headers.add(name: "platform", value: deviceInfo.platform)
        request.headers.add(name: "language", value: deviceInfo.language)
        request.headers.add(name: "timezone", value: deviceInfo.timezone)
        request.headers.add(name: "device", value: deviceInfo.device)
        request.headers.add(name: "system_version", value: deviceInfo.systemVersion)

        return request
    }
}
