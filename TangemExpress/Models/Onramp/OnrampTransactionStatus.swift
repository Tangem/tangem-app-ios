//
//  OnrampTransactionStatus.swift
//  TangemApp
//
//  Created by Sergey Balashov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum OnrampTransactionStatus: String, Codable {
    case created
    case expired
    case waitingForPayment = "waiting-for-payment"
    case paymentProcessing = "payment-processing"
    case verifying
    case failed
    case paid
    case sending
    case finished
    case paused
}
