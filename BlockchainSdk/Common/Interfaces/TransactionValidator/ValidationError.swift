//
//  ValidationError.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ValidationError: Hashable, LocalizedError {
    case balanceNotFound
    case invalidAmount
    case amountExceedsBalance
    case invalidFee
    case feeExceedsBalance
    case totalExceedsBalance

    case dustAmount(minimumAmount: Amount)
    case dustChange(minimumAmount: Amount)
    case minimumBalance(minimumBalance: Amount)
    case maximumUTXO(blockchainName: String, newAmount: Amount, maxUtxo: Int)
    case reserve(amount: Amount)
    
    case cardanoHasTokens(minimumAmount: Amount)
    case cardanoInsufficientBalanceToSendToken
    
    case insufficientFeeResource(type: FeeResourceType, current: Decimal, max: Decimal)
    case amountExeedsFeeResourceCapacity(type: FeeResourceType, availableAmount: Decimal)
    case feeExceedsMaxFeeResource

    public var errorDescription: String? {
        switch self {
        case .balanceNotFound, .cardanoInsufficientBalanceToSendToken, .cardanoHasTokens:
            return WalletError.empty.localizedDescription
        case .amountExceedsBalance:
            return "send_validation_amount_exceeds_balance".localized
        case .dustAmount(let minimumAmount):
            return String(format: "send_error_dust_amount_format".localized, minimumAmount.description)
        case .dustChange(let minimumAmount):
           return String(format: "send_error_dust_change_format".localized, minimumAmount.description)
        case .minimumBalance(let minimumBalance):
            return String(format: "send_error_minimum_balance_format".localized, minimumBalance.string(roundingMode: .plain))
        case .feeExceedsBalance, .feeExceedsMaxFeeResource:
            return "send_validation_invalid_fee".localized
        case .invalidAmount, .amountExeedsFeeResourceCapacity:
            return "send_validation_invalid_amount".localized
        case .invalidFee:
            return "send_error_invalid_fee_value".localized
        case .totalExceedsBalance:
            return "send_validation_invalid_total".localized
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxo):
            return "common_utxo_validate_withdrawal_message_warning".localized(
                [blockchainName, maxUtxo, newAmount.description]
            )
        case .reserve(let amount):
            return String(format: "send_error_no_target_account".localized, amount.description)
        case let .insufficientFeeResource(.mana, current, max):
            return String(format: "koinos_insufficient_mana_to_send_koin_description", "\(current)", "\(max)")
        }
    }
}
