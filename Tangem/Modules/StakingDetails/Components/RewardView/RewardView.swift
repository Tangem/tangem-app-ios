//
//  RewardView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct RewardView: View {
    let data: RewardViewData

    var body: some View {
        HStack(spacing: 4) {
            content
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    @ViewBuilder
    var content: some View {
        switch data.state {
        case .noRewards:
            Text(Localization.stakingDetailsNoRewardsToClaim)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        case .rewards(let fiatFormatted, let cryptoFormatted):
            Text(fiatFormatted)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Text(AppConstants.dotSign)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Text(cryptoFormatted)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
    }
}

#Preview("RewardView") {
    ZStack {
        Colors.Background.secondary.ignoresSafeArea()

        GroupedSection(
            [
                RewardViewData(state: .noRewards),
                RewardViewData(
                    state: .rewards(
                        fiatFormatted: "24.12$",
                        cryptoFormatted: "23.421 SOL"
                    )
                ),
            ]
        ) {
            RewardView(data: $0)
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
        .padding()
    }
}
