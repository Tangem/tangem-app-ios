//
//  SettingsUserWalletRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SettingsUserWalletRowView: View {
    @ObservedObject var viewModel: SettingsUserWalletRowViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            content
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!viewModel.isUserWalletLocked)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 12) {
            icon

            textViews

            Spacer()

            if !viewModel.isUserWalletLocked {
                Assets.chevron.image
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var icon: some View {
        image
            .frame(width: 36, height: 36)
            .skeletonable(
                isShown: viewModel.icon.isLoading,
                size: CGSize(width: 36, height: 22),
                paddings: EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
            )
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.icon {
        case .loading:
            Color.clear
        case .loaded(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .failedToLoad:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    @ViewBuilder
    private var textViews: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.name)
                .lineLimit(1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Text(viewModel.cardsCount)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                if viewModel.balanceState != .empty {
                    Text(AppConstants.dotSign)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    LoadableTokenBalanceView(
                        state: viewModel.balanceState,
                        style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                        loader: .init(size: CGSize(width: 40, height: 12))
                    )
                }
            }
            .lineLimit(1)
        }
    }
}

#Preview("SettingsUserWalletRowView") {
    ZStack {
        Colors.Background.tertiary.ignoresSafeArea()

        VStack {
            SettingsUserWalletRowView(
                viewModel: .init(
                    cardsCount: 3,
                    isUserWalletLocked: false,
                    userWalletNamePublisher: .just(output: "My wallet"),
                    totalBalancePublisher: .just(output: .loading(cached: .none)),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.walletCard.uiImage)),
                    tapAction: {}
                )
            )

            SettingsUserWalletRowView(
                viewModel: .init(
                    cardsCount: 2,
                    isUserWalletLocked: false,
                    userWalletNamePublisher: .just(output: "My wallet"),
                    totalBalancePublisher: .just(output: .failed(cached: .none, failedItems: [])),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.walletCard.uiImage)),
                    tapAction: {}
                )
            )

            SettingsUserWalletRowView(
                viewModel: .init(
                    cardsCount: 2,
                    isUserWalletLocked: false,
                    userWalletNamePublisher: .just(output: "Old wallet"),
                    totalBalancePublisher: .just(output: .loaded(balance: 96.75)),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.darkCard.uiImage)),
                    tapAction: {}
                )
            )

            SettingsUserWalletRowView(
                viewModel: .init(
                    cardsCount: 2,
                    isUserWalletLocked: true,
                    userWalletNamePublisher: .just(output: "Locked wallet"),
                    totalBalancePublisher: .just(output: .failed(cached: .none, failedItems: [])),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.darkCard.uiImage))
                        .delay(for: 4, scheduler: DispatchQueue.main)
                        .eraseToAnyPublisher(),
                    tapAction: {}
                )
            )
        }
        .padding()
    }
}
