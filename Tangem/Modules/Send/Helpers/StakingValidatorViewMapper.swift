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

    func mapToValidatorViewData(
        info: ValidatorInfo,
        subtitleType: ValidatorViewData.SubtitleType = .arp,
        detailsType: ValidatorViewData.DetailsType?
    ) -> ValidatorViewData {
        let subtitle: AttributedString?
        switch subtitleType {
        case .arp:
            var localizedPart = AttributedString("ARP")
            localizedPart.foregroundColor = Colors.Text.tertiary
            localizedPart.font = Fonts.Regular.footnote

            let arpPart = info.apr
                .map {
                    let formatted = percentFormatter.format($0, option: .staking)
                    var result = AttributedString(formatted)
                    result.foregroundColor = Colors.Text.accent
                    result.font = Fonts.Regular.footnote
                    return result
                }
            subtitle = localizedPart + " " + (arpPart ?? "")
        case .unboundPeriod(let days):
            var localizedPart = AttributedString(Localization.stakingDetailsUnbondingPeriod)
            localizedPart.foregroundColor = Colors.Text.tertiary
            localizedPart.font = Fonts.Regular.footnote

            var periodPart = AttributedString(days)
            periodPart.foregroundColor = Colors.Text.accent
            periodPart.font = Fonts.Regular.footnote
            subtitle = localizedPart + " " + periodPart
        }
        return ValidatorViewData(
            id: info.address,
            name: info.name,
            imageURL: info.iconURL,
            subtitle: subtitle,
            detailsType: detailsType
        )
    }
}
