//
//  NativeStakingView.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct NativeStakingView: View {
    let usdAmount: String
    let coinAmount: String
    let rewardsToClaim: String
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
                    Text(usdAmount)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    Text("•")
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    Text(coinAmount)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                }

                Text(Localization.stakingDetailsRewardsToClaim(rewardsToClaim))
                    .lineLimit(1)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            Spacer()

            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .padding(.trailing, 2)
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

#Preview {
    NativeStakingView(usdAmount: "456.34$", coinAmount: "5 SOL", rewardsToClaim: "0,43$", tapAction: {})
}
