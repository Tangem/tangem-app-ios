//
//  StakingValidatorViewMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingValidatorViewMapper {
    private let percentFormatter = PercentFormatter()

    enum ValidatorStakeState: Hashable {
        case unknown
        case warmup(period: String)
        case active(apr: Decimal?)
        case unbounding(period: String)

        var isUnstaked: Bool {
            if case .unbounding = self {
                return true
            }

            return false
        }
    }

    func mapToValidatorViewData(
        info: ValidatorInfo,
        state: ValidatorStakeState? = nil,
        detailsType: ValidatorViewData.DetailsType?
    ) -> ValidatorViewData {
        let state = state ?? .active(apr: info.apr)
        return ValidatorViewData(
            address: info.address,
            name: info.name,
            imageURL: info.iconURL,
            hasMonochromeIcon: state.isUnstaked,
            subtitle: subtitle(for: state),
            detailsType: detailsType
        )
    }

    private func subtitle(for state: ValidatorStakeState) -> AttributedString {
        switch state {
        case .unknown:
            .init(.unknown)
        case .warmup(let period):
            periodString(text: Localization.stakingDetailsWarmupPeriod, days: period)
        case .active(let apr):
            aprString(apr: apr)
        case .unbounding(let period):
            periodString(text: Localization.stakingDetailsUnbondingPeriod, days: period)
        }
    }

    private func aprString(apr: Decimal?) -> AttributedString {
        var descriptionPart = AttributedString(Localization.stakingDetailsApr)
        descriptionPart.foregroundColor = Colors.Text.tertiary
        descriptionPart.font = Fonts.Regular.footnote

        let percentFormatter = PercentFormatter()
        let valuePart = apr
            .map {
                let formatted = percentFormatter.format($0, option: .staking)
                var result = AttributedString(formatted)
                result.foregroundColor = Colors.Text.accent
                result.font = Fonts.Regular.footnote
                return result
            }
        return descriptionPart + " " + (valuePart ?? "")
    }

    private func periodString(text: String, days: String) -> AttributedString {
        var descriptionPart = AttributedString(text)
        descriptionPart.foregroundColor = Colors.Text.tertiary
        descriptionPart.font = Fonts.Regular.footnote

        var valuePart = AttributedString(days)
        valuePart.foregroundColor = Colors.Text.accent
        valuePart.font = Fonts.Regular.footnote
        return descriptionPart + " " + valuePart
    }
}
