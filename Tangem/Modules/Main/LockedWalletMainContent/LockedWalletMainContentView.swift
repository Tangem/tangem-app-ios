//
//  LockedWalletMainContentView.swift
//  Tangem
//
//  Created by Andrew Son on 16/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LockedWalletMainContentView: View {
    @ObservedObject var viewModel: LockedWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            if viewModel.isMultiWallet {
                multiWalletContent
            } else {
                singleWalletContent
            }
        }
        .padding(.horizontal, 16)
    }

    private var placeholderColor: Color {
        Colors.Field.primary
    }

    private var leadingCircle: some View {
        placeholderColor
            .frame(size: .init(bothDimensions: 36))
            .cornerRadiusContinuous(18)
    }

    private var multiWalletContent: some View {
        VStack(spacing: 14) {
            if let actionButtonsViewModel = viewModel.actionButtonsViewModel {
                ActionButtonsView(viewModel: actionButtonsViewModel)
                    .disabled(true)
            }

            NotificationView(input: viewModel.lockedNotificationInput)

            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.mainTokens)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)

                HStack(spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        leadingCircle

                        Colors.Field.primary
                            .frame(size: .init(bothDimensions: 14))
                            .cornerRadiusContinuous(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Colors.Background.primary, lineWidth: 2)
                            )
                            .offset(x: 4, y: -4)
                    }

                    tokenPlaceholders
                }
                .padding(14)
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)

            FixedSizeButtonWithLeadingIcon(
                title: Localization.organizeTokensTitle,
                icon: Assets.sliders.image,
                style: .disabled,
                action: {}
            )
            .disabled(true)

            Spacer()
        }
    }

    @ViewBuilder
    private var singleWalletContent: some View {
        ScrollableButtonsView(itemsHorizontalOffset: 14, buttonsInfo: viewModel.singleWalletButtonsInfo)

        NotificationView(input: viewModel.lockedNotificationInput)

        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(Localization.commonTransactions)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                Assets.compass.image
                    .foregroundColor(Colors.Icon.informative)

                Text(Localization.commonExplorer)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                leadingCircle

                tokenPlaceholders
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)

        Spacer()
    }

    private var tokenPlaceholders: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                placeholderColor
                    .frame(width: 70, height: 12)
                    .cornerRadiusContinuous(3)

                placeholderColor
                    .frame(width: 52, height: 12)
                    .cornerRadiusContinuous(3)
            }

            Spacer()

            VStack(spacing: 10) {
                ForEach(0 ... 1) { _ in
                    placeholderColor
                        .frame(width: 40, height: 12)
                        .cornerRadiusContinuous(3)
                }
            }
        }
    }
}

struct LockedWalletMainContentView_Previews: PreviewProvider {
    static var previews: some View {
        LockedWalletMainContentView(
            viewModel: .init(
                userWalletModel: FakeUserWalletModel.wallet3Cards,
                isMultiWallet: true,
                lockedUserWalletDelegate: nil
            )
        )
        .infinityFrame()
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))

        LockedWalletMainContentView(
            viewModel: .init(
                userWalletModel: FakeUserWalletModel.twins,
                isMultiWallet: false,
                lockedUserWalletDelegate: nil
            )
        )
        .infinityFrame()
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
