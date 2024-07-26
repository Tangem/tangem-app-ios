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

    private var banner: some View {
        Button(action: { viewModel.userDidTapBanner() }) {
            Assets.whatIsStakingBanner.image
                .resizable()
                .cornerRadiusContinuous(18)
                .overlay(alignment: .bottomLeading) {
                    whatIsStakingText
                }
        }
    }
    
    private var whatIsStakingText: some View {
        Text("What is staking")
            .font(Font.system(size: 24, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [Colors.Text.constantWhite, Colors.Text.stakingGradient],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding([.bottom, .leading], 16)
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
        walletModel: .mockETH,
        stakingManager: StakingManagerMock(),
        coordinator: StakingDetailsCoordinator()
    )

    static var previews: some View {
        StakingDetailsView(viewModel: viewModel)
    }
}
