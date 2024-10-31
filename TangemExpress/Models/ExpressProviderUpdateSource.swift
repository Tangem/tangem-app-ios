//
//  ExpressProviderUpdateSource.swift
//  TangemExpress
//
//  Created by GuitarKitty on 11.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum ExpressProviderUpdateSource {
    case amountChange
    case autoUpdate
    case pairChange

    public var isRequiredUpdateSelectedProvider: Bool {
        switch self {
        case .amountChange, .pairChange: true
        case .autoUpdate: false
        }
    }
}
