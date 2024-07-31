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
            content: {
                RewardView(data: $0)
            }, header: {
                DefaultHeaderView(Localization.stakingRewards)
            }, accessoryView: {
                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
            }
        )
        .interItemSpacing(12)
        .innerContentPadding(12)
    }

    private var activeValidatorsView: some View {
        validatorsView(
            validatorsViewData: viewModel.activeValidatorsViewData,
            header: Localization.stakingActive,
            footer: Localization.stakingActiveFooter
        )
    }

    private var unstakedValidatorsView: some View {
        validatorsView(
            validatorsViewData: viewModel.unstakedValidatorsViewData,
            header: Localization.stakingUnstaked,
            footer: Localization.stakingUnstakedFooter
        )
    }

    private func validatorsView(validatorsViewData: ValidatorsViewData?, header: String, footer: String) -> some View {
        GroupedSection(
            validatorsViewData,
            content: { data in
                ForEach(indexed: data.validators.indexed()) { validatorIndex, validator in
                    VStack {
                        ValidatorView(data: validator)
                        ValidatorView(data: validator)
                    }
                }
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
        walletModel: .mockETH,
        stakingManager: StakingManagerMock(),
        coordinator: StakingDetailsCoordinator()
    )

    static var previews: some View {
        StakingDetailsView(viewModel: viewModel)
    }
}
