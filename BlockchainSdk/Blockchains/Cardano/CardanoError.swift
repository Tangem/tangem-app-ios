//
//  CardanoError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum CardanoError: String, Error, LocalizedError {
    case noUnspents
    case lowAda

    public var errorDescription: String? {
        switch self {
        case .noUnspents:
            return "generic_error_code".localized(errorCodeDescription)
        case .lowAda:
            return "cardano_low_ada".localized
        }
    }

    private var errorCodeDescription: String {
        return "cardano_error \(errorCode)"
    }

    private var errorCode: Int {
        switch self {
        case .noUnspents:
            return 1
        case .lowAda:
            return 2
        }
    }
}
