//
//  ETHError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 17.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ETHError: Error, LocalizedError, DetailedError {
    case failedToParseTxCount
    case failedToParseBalance(value: String, address: String, decimals: Int)
    case failedToParseGasLimit
    case failedToParseFeeHistory
    case failedToParseAllowance
    case gasRequiredExceedsAllowance
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseTxCount, .failedToParseBalance, .failedToParseAllowance, .failedToParseFeeHistory:
            return "generic_error_code".localized(errorCodeDescription)
        case .failedToParseGasLimit: // TODO: refactor
            return "generic_error_code".localized(errorCodeDescription)
        case .gasRequiredExceedsAllowance:
            return "eth_gas_required_exceeds_allowance".localized
        case .unsupportedFeature:
            return "unsupportedFeature"
        }
    }
    
    public var detailedDescription: String? {
        switch self {
        case .failedToParseBalance(let value, let address, let decimals):
            return "value:\(value), address:\(address), decimals:\(decimals)"
        default:
            return nil
        }
    }
    
    private var errorCodeDescription: String {
        "eth_error \(errorCode)"
    }
    
    private var errorCode: Int {
        switch self {
        case .failedToParseTxCount:
            return 1
        case .failedToParseBalance:
            return 2
        case .failedToParseGasLimit:
            return 3
        case .failedToParseAllowance:
            return 4
        case .gasRequiredExceedsAllowance:
            return 5
        case .unsupportedFeature:
            return 6
        case .failedToParseFeeHistory:
            return 7
        }
    }
}
