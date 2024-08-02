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
        ZStack(alignment: .bottom) {
            GroupedScrollView(alignment: .leading, spacing: 14) {
                banner

                averageRewardingView

                GroupedSection(viewModel.detailsViewModels) {
                    DefaultRowView(viewModel: $0)
                }

                rewardView

                activeValidatorsView
                unstakedValidatorsView

                FixedSpacer(height: bottomViewHeight)
            }
            .interContentPadding(14)

            actionButton
        }
        .background(Colors.Background.secondary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.onAppear)
        .bottomSheet(
            item: $viewModel.descriptionBottomSheetInfo,
            backgroundColor: Colors.Background.tertiary
        ) {
            DescriptionBottomSheetView(
                info: DescriptionBottomSheetInfo(title: $0.title, description: $0.description)
            )
        }
    }

    @ViewBuilder
    private var banner: some View {
        if viewModel.displayHeaderView {
            Button(action: { viewModel.userDidTapBanner() }) {
                Assets.whatIsStakingBanner.image
                    .resizable()
                    .cornerRadiusContinuous(18)
            }
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
        GroupedSection(
            viewModel.rewardViewData,
            content: { data in
                Button(action: {}, label: {
                    RewardView(data: data)
                })
            }, header: {
                DefaultHeaderView(Localization.stakingRewards)
            }, accessoryView: {
                rewardAccossoryView
            }
        )
        .interItemSpacing(12)
        .innerContentPadding(12)
    }

    @ViewBuilder
    private var rewardAccossoryView: some View {
        if viewModel.rewardViewData?.hasRewards == true {
            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        }
    }

    private var activeValidatorsView: some View {
        validatorsView(
            validators: viewModel.activeValidators,
            header: Localization.stakingActive,
            footer: Localization.stakingActiveFooter
        )
    }

    private var unstakedValidatorsView: some View {
        validatorsView(
            validators: viewModel.unstakedValidators,
            header: Localization.stakingUnstaked,
            footer: Localization.stakingUnstakedFooter
        )
    }

    private func validatorsView(validators: [ValidatorViewData], header: String, footer: String) -> some View {
        GroupedSection(
            validators,
            content: { data in
                Button(action: {}, label: {
                    ValidatorView(data: data)
                })
            }, header: {
                DefaultHeaderView(header)
            }, footer: {
                Text(footer)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        )
        .interItemSpacing(10)
        .innerContentPadding(12)
    }

    private var actionButton: some View {
        MainButton(title: viewModel.buttonTitle) {
            viewModel.userDidTapActionButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .readGeometry(\.size.height, bindTo: $bottomViewHeight)
    }
}

struct StakingDetailsView_Preview: PreviewProvider {
    static let viewModel = StakingDetailsViewModel(
        walletModel: .mockETH,
        stakingManager: StakingManagerMock(),
        coordinator: StakingDetailsCoordinator()
    )

    static var previews: some View {
        StakingDetailsView(viewModel: viewModel)
    }
}
