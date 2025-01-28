//
//  ActiveStakingView.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActiveStakingViewData {
    let balance: BalanceState
    let rewards: RewardsState?

    enum BalanceState {
        case loadingError
        case balance(BalanceFormatted, action: () -> Void)
    }

    enum RewardsState {
        case noRewards
        case rewardsToClaim(String)
    }
}

struct ActiveStakingView: View {
    let data: ActiveStakingViewData

    var body: some View {
        switch data.balance {
        case .loadingError:
            content
        case .balance(_, let action):
            Button(action: action, label: { content })
        }
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.stakingNative)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                balanceView

                rewardsView
            }

            Spacer()

            chevronView
        }
    }

    @ViewBuilder
    private var balanceView: some View {
        switch data.balance {
        case .loadingError:
            Text(Localization.stakingNotificationNetworkErrorText)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        case .balance(let balance, _):
            HStack(spacing: 4) {
                SensitiveText(balance.fiat)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                Text(AppConstants.dotSign)
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                SensitiveText(balance.crypto)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }
            .truncationMode(.middle)
            .lineLimit(1)
        }
    }

    @ViewBuilder
    private var rewardsView: some View {
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

    @ViewBuilder
    private var chevronView: some View {
        switch data.balance {
        case .loadingError:
            EmptyView()
        case .balance:
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
            data: ActiveStakingViewData(
                balance: .balance(.init(crypto: "5 SOL", fiat: "456.34$"), action: {}),
                rewards: .rewardsToClaim("0,43$")
            )
        )
        ActiveStakingView(
            data: ActiveStakingViewData(
                balance: .balance(.init(crypto: "5 SOL", fiat: "456.34$"), action: {}),
                rewards: .noRewards
            )
        )
        ActiveStakingView(
            data: ActiveStakingViewData(
                balance: .loadingError,
                rewards: .rewardsToClaim("0,43$")
            )
        )
    }
}
