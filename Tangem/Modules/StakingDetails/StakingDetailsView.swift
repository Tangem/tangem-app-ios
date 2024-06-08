//
//  StakingDetailsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingDetailsView: View {
    @ObservedObject private var viewModel: StakingDetailsViewModel
    @State private var bottomViewHeight: CGFloat = .zero

    init(viewModel: StakingDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                GroupedScrollView(alignment: .leading, spacing: 14) {
                    banner

                    averageRewardingView

                    GroupedSection(viewModel.detailsViewModels) {
                        DefaultRowView(viewModel: $0)
                    }

                    rewardView

                    FixedSpacer(height: bottomViewHeight)
                }
                .interContentPadding(14)

                actionButton
            }
            .background(Colors.Background.secondary)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var banner: some View {
        Button(action: { viewModel.userDidTapBanner() }) {
            Assets.whatIsStakingBanner.image
                .resizable()
                .cornerRadiusContinuous(18)
        }
    }

    private var averageRewardingView: some View {
        GroupedSection(viewModel.averageRewardingViewData) {
            AverageRewardingView(data: $0)
        } header: {
            DefaultHeaderView(Localization.stakingDetailsAverageRewardRate)
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
    }

    private var rewardView: some View {
        GroupedSection(viewModel.rewardViewData) {
            RewardView(data: $0)
        } header: {
            DefaultHeaderView(Localization.stakingRewards)
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
    }

    private var actionButton: some View {
        MainButton(title: Localization.commonStake) {
            viewModel.userDidTapActionButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .readGeometry(\.size.height, bindTo: $bottomViewHeight)
    }
}

struct StakingDetailsView_Preview: PreviewProvider {
    static let viewModel = StakingDetailsViewModel(
        inputData: .init(
            tokenItem: .blockchain(
                .init(
                    .solana(
                        curve: .ed25519_slip0010,
                        testnet: false
                    ),
                    derivationPath: .none
                )
            ),
            monthEstimatedProfit: 56.25,
            available: 15,
            staked: 0,
            minAPR: 3.54,
            maxAPR: 5.06,
            unbonding: .days(3),
            minimumRequirement: 0.000028,
            rewardClaimingType: .auto,
            rewardType: .apr,
            warmupPeriod: .days(3),
            rewardScheduleType: .block
        ),
        coordinator: StakingDetailsCoordinator()
    )

    static var previews: some View {
        StakingDetailsView(viewModel: viewModel)
    }
}
