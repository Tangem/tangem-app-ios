//
//  StakingFeeIncludedCalculator.swift
//  TangemApp
//
//  Created by Sergey Balashov on 16.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct StakingFeeIncludedCalculator: FeeIncludedCalculator {
    private let tokenItem: TokenItem
    private let validator: TransactionValidator

    init(tokenItem: TokenItem, validator: TransactionValidator) {
        self.tokenItem = tokenItem
        self.validator = validator
    }

    func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool {
        // For tron coin we don't included fee
        if case .tron = tokenItem.blockchain {
            return false
        }

        guard fee.amount.type == amount.type, amount >= fee.amount else {
            return false
        }

        do {
            try validator.validate(amount: amount, fee: fee)
            return false
        } catch ValidationError.totalExceedsBalance {
            return true
        } catch {
            return false
        }
    }
}
