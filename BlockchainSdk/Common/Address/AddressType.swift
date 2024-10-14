//
//  AddressType.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum AddressType: String, Equatable {
    case `default`
    case legacy
    
    public var defaultLocalizedName: String {
        switch self {
        case .default:
            return "address_type_default".localized
        case .legacy:
            return "address_type_legacy".localized
        }
    }
}

extension AddressType: Comparable {
    public static func < (lhs: AddressType, rhs: AddressType) -> Bool {
        switch (lhs, rhs) {
        case (.default, legacy):
            return true
        default:
            return false
        }
    }
}
