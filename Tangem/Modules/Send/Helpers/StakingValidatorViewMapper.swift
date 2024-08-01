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
        case active(apr: Decimal?)
        case unstaked(unboundingPeriod: String)

        var isUnstaked: Bool {
            if case .unstaked = self {
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
            id: info.address,
            name: info.name,
            imageURL: info.iconURL,
            hasMonochromeIcon: state.isUnstaked,
            subtitle: subtitle(for: state),
            detailsType: detailsType
        )
    }

    private func subtitle(for state: ValidatorStakeState) -> AttributedString {
        switch state {
        case .active(let apr):
            aprString(apr: apr)
        case .unstaked(let unboundingPeriod):
            unboundingPeriodString(unboundingPeriodDays: unboundingPeriod)
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

    private func unboundingPeriodString(unboundingPeriodDays: String) -> AttributedString {
        var descriptionPart = AttributedString(Localization.stakingDetailsUnbondingPeriod)
        descriptionPart.foregroundColor = Colors.Text.tertiary
        descriptionPart.font = Fonts.Regular.footnote

        var valuePart = AttributedString(unboundingPeriodDays)
        valuePart.foregroundColor = Colors.Text.accent
        valuePart.font = Fonts.Regular.footnote
        return descriptionPart + " " + valuePart
    }
}
