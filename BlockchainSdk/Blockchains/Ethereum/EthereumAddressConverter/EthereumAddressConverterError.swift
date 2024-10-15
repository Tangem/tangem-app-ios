//
//  EthereumAddressConverterError.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum EthereumAddressConverterError: LocalizedError {
    case failedToConvertAddress(error: Error)

    var errorDescription: String? {
        switch self {
        case .failedToConvertAddress(error: let error):
            return "failedToConvertAddress: \(error.localizedDescription)"
        }
    }
}
