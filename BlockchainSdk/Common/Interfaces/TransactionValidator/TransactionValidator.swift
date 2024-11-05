//
//  TransactionValidator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

public protocol TransactionValidator: WalletProvider {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws
    func validate(amount: Amount, fee: Fee) throws
}

public enum DestinationType: Hashable {
    /// Will generate a dummy destination address for verification
    case generate
    /// The specified address will be used for verification
    case address(String)
}

// MARK: - Default implementation

public extension TransactionValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validateAmounts(amount: amount, fee: fee.amount)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
    }

    /// Validation will be doing with `amount`, `fee` and `destinationAddress`  from the `Transaction`
    func validate(transaction: Transaction) async throws {
        try await validate(amount: transaction.amount, fee: transaction.fee, destination: .address(transaction.destinationAddress))
    }
}

// MARK: - Simple sending amount validation (Amount, Fee)

public extension TransactionValidator {
    /// Method for the sending amount and fee validation
    /// Has default implementation just for checking balance and numbers
    func validateAmounts(amount: Amount, fee: Amount) throws {
        try validate(amount: amount)
        try validate(fee: fee)
        try validateTotal(amount: amount, fee: fee)
    }

    func validate(amount: Amount) throws {
        guard amount.value >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        guard balance >= amount else {
            throw ValidationError.amountExceedsBalance
        }
    }

    func validate(fee: Amount) throws {
        guard fee.value >= 0 else {
            throw ValidationError.invalidFee
        }

        guard let feeBalance = wallet.amounts[fee.type] else {
            throw ValidationError.balanceNotFound
        }

        guard feeBalance >= fee else {
            throw ValidationError.feeExceedsBalance
        }
    }

    func validateTotal(amount: Amount, fee: Amount) throws {
        // If we try to spend all amount from coin
        guard amount.type == fee.type else {
            // Safely return because all the checks were above
            return
        }

        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        let total = amount + fee

        guard balance >= total else {
            throw ValidationError.totalExceedsBalance
        }
    }
}

// MARK: - DustRestrictable

extension TransactionValidator where Self: DustRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateDust(amount: amount, fee: fee.amount)
    }
}

// MARK: - MinimumBalanceRestrictable

extension TransactionValidator where Self: MinimumBalanceRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateMinimumBalance(amount: amount, fee: fee.amount)
    }
}

// MARK: - MaximumAmountRestrictable

extension TransactionValidator where Self: MaximumAmountRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateMaximumAmount(amount: amount, fee: fee.amount)
    }
}

// MARK: - DustRestrictable, MaximumAmountRestrictable e.g. KaspaWalletManager

extension TransactionValidator where Self: MaximumAmountRestrictable, Self: DustRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateDust(amount: amount, fee: fee.amount)
        try validateMaximumAmount(amount: amount, fee: fee.amount)
    }
}

// MARK: - DustRestrictable, CardanoTransferRestrictable e.g. CardanoWalletManager

extension TransactionValidator where Self: DustRestrictable, Self: CardanoTransferRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateCardanoTransfer(amount: amount, fee: fee)
        try validateDust(amount: amount, fee: fee.amount)
    }
}

// MARK: - ReserveAmountRestrictable

extension TransactionValidator where Self: ReserveAmountRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try validateAmounts(amount: amount, fee: fee.amount)

        switch destination {
        case .generate:
            try await validateReserveAmount(amount: amount, addressType: .notCreated)
        case .address(let string):
            try await validateReserveAmount(amount: amount, addressType: .address(string))
        }
    }
}

// MARK: - FeeResourceRestrictable

extension TransactionValidator where Self: FeeResourceRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validate(amount: amount)
        try validateFeeResource(amount: amount, fee: fee.amount)
    }
}
