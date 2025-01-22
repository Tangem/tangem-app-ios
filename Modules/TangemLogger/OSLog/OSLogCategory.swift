//
//  OSLogCategory.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum OSLogCategory: Hashable {
    // Common
    case app(_ subcategory: String?)
    case network
    case analytics

    // Frameworks
    case tangemSDK
    case blockchainSDK
    case express
    case visa
    case staking
    case logFileWriter

    var name: String {
        switch self {
        case .app(.none): "App"
        case .app(.some(let string)): "App [\(string)]"
        case .network: "Network"
        case .analytics: "Analytics"
        case .tangemSDK: "TangemSDK"
        case .blockchainSDK: "BlockchainSDK"
        case .express: "Express"
        case .visa: "Visa"
        case .staking: "Staking"
        case .tangemSDK: "TangemSDK"
        case .blockchainSDK: "BlockchainSDK"
        case .logFileWriter: "LogFileWriter"
        }
    }
}
