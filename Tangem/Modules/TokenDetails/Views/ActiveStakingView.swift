//
//  ActiveStakingView.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActiveStakingViewData {
    let usdAmount: String
    let coinAmount: String
    let rewardsToClaim: String?

    var rewardsToClaimText: String {
        rewardsToClaim.flatMap { Localization.stakingDetailsRewardsToClaim($0) }
            ?? Localization.stakingDetailsNoRewardsToClaim
    }
}

struct ActiveStakingView: View {
    let data: ActiveStakingViewData
    let tapAction: () -> Void

    var body: some View {
        Button(action: tapAction, label: { content })
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.stakingNative)
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 4) {
                    Text(data.usdAmount)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    Text(AppConstants.dotSign)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    Text(data.coinAmount)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                }

                Text(data.rewardsToClaimText)
                    .lineLimit(1)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            Spacer()

            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .padding(.trailing, 2)
        }
    }
}

#Preview {
    VStack {
        ActiveStakingView(
            data: ActiveStakingViewData(usdAmount: "456.34$", coinAmount: "5 SOL", rewardsToClaim: "0,43$"),
            tapAction: {}
        )
        ActiveStakingView(
            data: ActiveStakingViewData(usdAmount: "456.34$", coinAmount: "5 SOL", rewardsToClaim: nil),
            tapAction: {}
        )
    }
}
