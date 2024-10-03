//
//  OnboardingMessagesView.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingMessagesView: View {
    let title: String
    let subtitle: String
    let onTitleTapCallback: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .frame(maxWidth: .infinity)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(Colors.Old.tangemGrayDark6)
                .padding(.bottom, 14)
                .transition(.opacity)
                .id("onboarding_title_\(title)")

            Text(subtitle)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Colors.Text.secondary)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
                .padding(.horizontal, 20)
                .id("onboarding_subtitle_\(subtitle)")
        }
    }
}

struct OnboardingMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            OnboardingMessagesView(
                title: "Create wallet",
                subtitle: "Tap card to create wallet"
            ) {}.background(Color.red)

            OnboardingMessagesView(
                title: "Create wallet",
                subtitle: "All the backup cards can be used as full-functional wallets with the identical keys."
            ) {}.background(Color.green)
        }
        .padding(.horizontal, 80)
    }
}
