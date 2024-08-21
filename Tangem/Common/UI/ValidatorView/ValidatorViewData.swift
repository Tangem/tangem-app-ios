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
            return nil
        case .selection(let apr):
            return string("\(Localization.stakingDetailsAnnualPercentageRate) \(apr)", accent: apr)
        case .warmup(let period):
            return string("\(Localization.stakingDetailsWarmupPeriod) \(period)", accent: period)
        case .active(let apr):
            return string("\(Localization.stakingDetailsApr) \(apr)", accent: apr)
        case .unbounding(let unlitDate):
            let (full, accent) = preparedUntil(unlitDate)
            return string(full, accent: accent)
        case .withdraw:
            return string(Localization.stakingReadyToWithdraw)
        }
    }

    private func preparedUntil(_ date: Date) -> (full: String, accent: String) {
        if Calendar.current.isDateInToday(date) {
            return (Localization.stakingUnbonding(Localization.commonToday), Localization.commonToday)
        }

        guard let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day else {
            let formatted = date.formatted(.dateTime)
            return (Localization.stakingUnbondingIn(formatted), formatted)
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        let formatted = formatter.string(from: DateComponents(day: days)) ?? days.formatted()

        return (Localization.stakingUnbondingIn(formatted), formatted)
    }

    private func string(_ text: String, accent: String? = nil) -> AttributedString {
        var string = AttributedString(text)
        string.foregroundColor = Colors.Text.tertiary
        string.font = Fonts.Regular.caption1

        if let accent, let range = string.range(of: accent) {
            string[range].foregroundColor = Colors.Text.accent
            string[range].font = Fonts.Regular.caption1
        }

        return string
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
