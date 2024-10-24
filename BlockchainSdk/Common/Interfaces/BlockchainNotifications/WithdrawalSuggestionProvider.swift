//
//  WithdrawalNotificationProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol WithdrawalNotificationProvider {
    @available(*, deprecated, message: "Use WithdrawalNotificationProvider.withdrawalSuggestion")
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning?
    
    func withdrawalNotification(amount: Amount, fee: Fee) -> WithdrawalNotification?
}

@available(*, deprecated, message: "Use WithdrawalNotificationProvider.withdrawalSuggestion")
public struct WithdrawalWarning: Hashable {
    public let warningMessage: String
    public let reduceMessage: String
    public var ignoreMessage: String? = nil
    public let suggestedReduceAmount: Amount
}

public enum WithdrawalNotification: Hashable {
    case feeIsTooHigh(reduceAmountBy: Amount)
    case cardanoWillBeSendAlongToken(amount: Amount)
}
