//
//  DeviceInfo.swift
//  TangemNetworkUtils
//
//  Created by Alexander Osokin on 09.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//
import Foundation
import UIKit
import TangemFoundation

public struct DeviceInfo {
    public let platform: String
    public let version: String
    public let language: String
    public let timezone: String
    public let device: String
    public let systemVersion: String

    public init() {
        platform = Constants.platformName
        version = InfoDictionaryUtils.version.value() ?? Constants.commonUnknown
        language = Locale.current.languageCode ?? Constants.commonUnknown
        timezone = TimeZone.current.identifier
        device = UIDevice.current.iPhoneModel?.name ?? Constants.commonUnknown
        systemVersion = UIDevice.current.systemVersion
    }
}

// MARK: - Constants

private extension DeviceInfo {
    enum Constants {
        static let platformName = "ios"
        static let commonUnknown = "unknown"
    }
}
