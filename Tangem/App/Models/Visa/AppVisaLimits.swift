//
//  AppVisaLimits.swift
//  Tangem
//
//  Created by Andrew Son on 22/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct AppVisaLimits {
    let oldLimit: AppVisaLimit
    let newLimit: AppVisaLimit
    let changeDate: Date

    var currentLimit: AppVisaLimit {
        if changeDate > Date() {
            return oldLimit
        }

        return newLimit
    }

    init(limits: VisaLimits) {
        oldLimit = .init(limit: limits.oldLimit)
        newLimit = .init(limit: limits.newLimit)
        changeDate = limits.changeDate
    }

    init(oldLimit: AppVisaLimit, newLimit: AppVisaLimit, changeDate: Date) {
        self.oldLimit = oldLimit
        self.newLimit = newLimit
        self.changeDate = changeDate
    }
}

struct AppVisaLimit {
    let limitExpirationDate: Date
    let limitDurationSeconds: Double
    let singleTransaction: Decimal?
    let otpLimit: Decimal?
    let spentOTPAmount: Decimal?
    let noOTPLimit: Decimal?
    let spentNoOTPAmount: Decimal?

    var actualExpirationDate: Date {
        if limitExpirationDate >= Date() {
            return limitExpirationDate
        } else {
            let availableDate = Calendar.current.date(byAdding: .second, value: Int(limitDurationSeconds), to: Date()) ?? Date()
            return availableDate
        }
    }

    var remainingOTPAmount: Decimal? {
        guard let otpLimit, let spentOTPAmount else {
            return nil
        }

        if limitExpirationDate >= Date() {
            return otpLimit - spentOTPAmount
        }

        return otpLimit
    }

    var remainingNoOTPAmount: Decimal? {
        guard let noOTPLimit, let spentNoOTPAmount else {
            return nil
        }

        if limitExpirationDate >= Date() {
            return noOTPLimit - spentNoOTPAmount
        }

        return noOTPLimit
    }

    init(limit: VisaLimit) {
        limitExpirationDate = limit.expirationDate
        limitDurationSeconds = limit.limitDurationSeconds
        singleTransaction = limit.singleTransaction
        otpLimit = limit.otpLimit
        spentOTPAmount = limit.spentOTPAmount
        noOTPLimit = limit.noOTPLimit
        spentNoOTPAmount = limit.spentNoOTPAmount
    }

    init(
        limitExpirationDate: Date,
        limitDurationSeconds: Double,
        singleTransaction: Decimal?,
        otpLimit: Decimal?,
        spentOTPAmount: Decimal?,
        noOTPLimit: Decimal?,
        spentNoOTPAmount: Decimal?
    ) {
        self.limitExpirationDate = limitExpirationDate
        self.limitDurationSeconds = limitDurationSeconds
        self.singleTransaction = singleTransaction
        self.otpLimit = otpLimit
        self.spentOTPAmount = spentOTPAmount
        self.noOTPLimit = noOTPLimit
        self.spentNoOTPAmount = spentNoOTPAmount
    }
}
