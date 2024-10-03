//
//  VisaLimits.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaLimits {
    public let oldLimit: VisaLimit
    public let newLimit: VisaLimit
    public let changeDate: Date
}

public struct VisaLimit {
    public let expirationDate: Date
    public let limitDurationSeconds: Double
    public let singleTransaction: Decimal?
    public let otpLimit: Decimal?
    public let spentOTPAmount: Decimal?
    public let noOTPLimit: Decimal?
    public let spentNoOTPAmount: Decimal?
}
