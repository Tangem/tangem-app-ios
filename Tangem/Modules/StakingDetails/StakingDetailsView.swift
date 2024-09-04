//
//  StakingDetailsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingDetailsView: View {
    @ObservedObject var viewModel: StakingDetailsViewModel

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 14) {
            if !viewModel.hideStakingInfoBanner {
                banner
            }

            GroupedSection(viewModel.detailsViewModels) { data in
                DefaultRowView(viewModel: data)
                    .if(viewModel.detailsViewModels.first?.id == data.id) {
                        $0.appearance(.init(detailsColor: Colors.Text.accent))
                    }
            }

            rewardView

            activeValidatorsView

            unstakedValidatorsView
        }
        .interContentPadding(14)
        .refreshable {
            await Task { await viewModel.refresh() }.value
        }
        .safeAreaInset(edge: .bottom) {
            actionButton
        }
        .background(Colors.Background.secondary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.onAppear)
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
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
        Button(action: viewModel.userDidTapBanner) {
            ZStack(alignment: .leading) {
                Assets.whatIsStakingBanner.image
                    .resizable()
                    .cornerRadiusContinuous(18)
                whatIsStakingText
                    .padding(.leading, 14)
            }
        }
        .overlay(alignment: .topTrailing) {
            closeBannerButton
        }
    }

    private var whatIsStakingText: some View {
        Text(Localization.stakingDetailsBannerText)
            .font(Fonts.Bold.title1)
            .foregroundStyle(
                LinearGradient(
                    colors: [Colors.Text.constantWhite, Colors.Text.stakingGradient],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private var closeBannerButton: some View {
        Button(action: {
            withAnimation {
                viewModel.userDidTapHideBanner()
            }
        }) {
            Assets.cross.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.constant)
                .opacity(0.5)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
        }
    }

    @ViewBuilder
    private var rewardView: some View {
        GroupedSection(viewModel.rewardViewData) { data in
            RewardView(data: data)
        } header: {
            DefaultHeaderView(Localization.stakingRewards)
                .padding(.top, 8)
        }
        .innerContentPadding(4)
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
        GroupedSection(validators) { data in
            ValidatorView(data: data)
        } header: {
            DefaultHeaderView(header)
                .padding(.top, 12)
        } footer: {
            Text(footer)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
        .interItemSpacing(0)
        .innerContentPadding(0)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionButtonType = viewModel.actionButtonType {
            MainButton(
                title: actionButtonType.title,
                isLoading: viewModel.actionButtonLoading,
                isDisabled: viewModel.actionButtonDisabled
            ) {
                viewModel.userDidTapActionButton()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
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
