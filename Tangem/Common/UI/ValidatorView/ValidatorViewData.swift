//
//  ValidatorViewData.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ValidatorViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let address: String
    let name: String
    let imageURL: URL?
    let subtitleType: SubtitleType?
    let detailsType: DetailsType?

    var isIconMonochrome: Bool {
        switch subtitleType {
        case .selection, .warmup, .active, .none: false
        case .unbounding, .withdraw: true
        }
    }

    var subtitle: AttributedString? {
        switch subtitleType {
        case .none:
            nil
        case .selection(let percentFormatted):
            string(Localization.stakingDetailsAnnualPercentageRate, accent: percentFormatted)
        case .warmup(let percentFormatted):
            string(Localization.stakingDetailsWarmupPeriod, accent: percentFormatted)
        case .active(let percentFormatted):
            string(Localization.stakingDetailsApr, accent: percentFormatted)
        case .unbounding(let unlitDate):
            unboundingUntilFormatted(unlitDate)
        case .withdraw:
            string("Ready to withdraw", accent: "")
        }
    }

    private func unboundingUntilFormatted(_ date: Date) -> AttributedString {
        if Calendar.current.isDateInToday(date) {
            return string(Localization.stakingDetailsUnbondingPeriod, accent: Localization.commonToday)
        }

        guard let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day else {
            return string(Localization.stakingDetailsUnbondingPeriod, accent: date.formatted(.dateTime))
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]

        let daysFormatted = formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        return string(Localization.stakingDetailsUnbondingPeriod, accent: daysFormatted)
    }

    private func string(_ text: String, accent: String) -> AttributedString {
        var descriptionPart = AttributedString(text)
        descriptionPart.foregroundColor = Colors.Text.tertiary
        descriptionPart.font = Fonts.Regular.caption1

        var valuePart = AttributedString(accent)
        valuePart.foregroundColor = Colors.Text.accent
        valuePart.font = Fonts.Regular.caption1
        return descriptionPart + " " + valuePart
    }
}

extension ValidatorViewData {
    enum SubtitleType: Hashable {
        case warmup(period: String)
        case active(apr: String)
        case unbounding(until: Date)
        case withdraw
        case selection(percentFormatted: String)
    }

    enum DetailsType: Hashable {
        case checkmark
        case balance(_ balance: BalanceInfo, action: (() -> Void)? = nil)

        static func == (lhs: ValidatorViewData.DetailsType, rhs: ValidatorViewData.DetailsType) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .checkmark: hasher.combine("checkmark")
            case .balance(let balance, _): hasher.combine(balance)
            }
        }
    }
}
