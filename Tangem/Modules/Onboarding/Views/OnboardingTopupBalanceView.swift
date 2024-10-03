//
//  OnboardingTopupBalanceView.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingTopupBalanceUpdater: View {
    let balance: String
    let frame: CGSize
    let offset: CGSize
    let refreshAction: () -> Void
    let refreshButtonState: OnboardingCircleButton.State
    let refreshButtonSize: OnboardingCircleButton.Size
    let opacity: Double

    var body: some View {
        Group {
            VStack(spacing: 0) {
                Text(Localization.commonBalanceTitle.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Colors.Old.tangemGrayDark)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                Text(balance)
                    .multilineTextAlignment(.center)
                    .truncationMode(.middle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.3)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Colors.Old.tangemGrayDark6)
                    // .frame(maxWidth: max(frame.width - 26, 0), maxHeight: frame.height * 0.155)
                    .transition(.opacity)
                    .id("onboarding_balance_\(balance)")
                    .fixedSize()
            }
            .offset(offset)

            OnboardingCircleButton(
                refreshAction: refreshAction,
                state: refreshButtonState,
                size: refreshButtonSize
            )
            .offset(x: 0, y: offset.height + frame.height / 2)
        }
        .opacity(opacity)
    }
}

struct OnboardingTopupBalanceView: View {
    let backgroundFrameSize: CGSize
    let cornerSize: CGFloat
    let backgroundOffset: CGSize

    let balance: String
    let balanceUpdaterFrame: CGSize
    let balanceUpdaterOffset: CGSize

    let refreshAction: () -> Void
    let refreshButtonState: OnboardingCircleButton.State
    let refreshButtonSize: OnboardingCircleButton.Size
    let refreshButtonOpacity: Double

    var body: some View {
        ZStack {
            Rectangle()
                .frame(size: backgroundFrameSize)
                .cornerRadius(cornerSize)
                .foregroundColor(Colors.Button.secondary)
                .opacity(0.8)
                .offset(backgroundOffset)
            OnboardingTopupBalanceUpdater(
                balance: balance,
                frame: balanceUpdaterFrame,
                offset: balanceUpdaterOffset,
                refreshAction: {
                    refreshAction()
                },
                refreshButtonState: refreshButtonState,
                refreshButtonSize: refreshButtonSize,
                opacity: refreshButtonOpacity
            )
        }
    }
}

struct OnboardingTopupBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingTopupBalanceView(
            backgroundFrameSize: CGSize(width: 300, height: 275),
            cornerSize: 20,
            backgroundOffset: CGSize(width: 0, height: 0),
            balance: "0.00 BTC",
            balanceUpdaterFrame: CGSize(width: 100, height: 200),
            balanceUpdaterOffset: CGSize(width: 0, height: 40),
            refreshAction: {},
            refreshButtonState: .refreshButton,
            refreshButtonSize: .medium,
            refreshButtonOpacity: 1
        )
    }
}
