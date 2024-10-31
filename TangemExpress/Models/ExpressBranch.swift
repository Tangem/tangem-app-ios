//
//  ExpressBranch.swift
//  TangemApp
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum ExpressBranch: String, Hashable {
    case swap
    case onramp

    var supportedProviderTypes: [ExpressProviderType] {
        switch self {
        case .swap: [.dex, .cex, .dexBridge]
        case .onramp: [.onramp]
        }
    }
}
