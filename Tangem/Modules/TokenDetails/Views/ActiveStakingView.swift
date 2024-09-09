//
//  ActiveStakingView.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActiveStakingViewData {
    let balance: WalletModel.BalanceFormatted
    let rewards: RewardsState?

    enum RewardsState {
        case noRewards
        case rewardsToClaim(String)
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
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 4) {
                    SensitiveText(data.balance.fiat)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    Text(AppConstants.dotSign)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    SensitiveText(data.balance.crypto)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                }

                switch data.rewards {
                case .none:
                    EmptyView()
                case .noRewards:
                    Text(Localization.stakingDetailsNoRewardsToClaim)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                case .rewardsToClaim(let string):
                    SensitiveText(builder: Localization.stakingDetailsRewardsToClaim, sensitive: string)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
            .lineLimit(1)

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
            data: ActiveStakingViewData(balance: .init(crypto: "5 SOL", fiat: "456.34$"), rewards: .rewardsToClaim("0,43$")),
            tapAction: {}
        )
        ActiveStakingView(
            data: ActiveStakingViewData(balance: .init(crypto: "5 SOL", fiat: "456.34$"), rewards: .noRewards),
            tapAction: {}
        )
    }
}
