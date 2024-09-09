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

    @State private var viewGeometryInfo: GeometryInfo = .zero
    @State private var contentSize: CGSize = .zero
    @State private var bottomViewSize: CGSize = .zero

    private var spacer: CGFloat {
        var height = viewGeometryInfo.frame.height
        height -= contentSize.height
        height -= bottomViewSize.height
        return max(0, height)
    }

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: .zero) {
            VStack(spacing: 14) {
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

                GroupedSection(viewModel.stakes) { data in
                    StakingDetailsStakeView(data: data)
                } header: {
                    DefaultHeaderView(Localization.stakingYourStakes)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .separatorStyle(.none)
                .interItemSpacing(0)
                .innerContentPadding(0)
            }
            .readGeometry(\.frame.size, bindTo: $contentSize)

            bottomView
        }
        .readGeometry(bindTo: $viewGeometryInfo)
        .refreshable {
            await Task { await viewModel.refresh() }.value
        }
        .background(Colors.Background.secondary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
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

    @ViewBuilder
    private var bottomView: some View {
        VStack(spacing: 12) {
            FixedSpacer(height: spacer)

            VStack(spacing: 12) {
                legalView

                actionButton
            }
            .readGeometry(\.frame.size, bindTo: $bottomViewSize)
        }
        // To force `.animation(nil)` behaviour
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    @ViewBuilder
    private var legalView: some View {
        Text(viewModel.legalText)
            .multilineTextAlignment(.center)
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
