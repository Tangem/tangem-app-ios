//
//  CardanoError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum CardanoError: String, Error, LocalizedError {
    case noUnspents
    case lowAda

    var errorDescription: String? {
        switch self {
        case .noUnspents:
            return Localization.genericErrorCode(errorCodeDescription)
        case .lowAda:
            return Localization.cardanoLowAda
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
