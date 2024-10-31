//
//  OnboardingSeedPassphraseInfoBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 15/03/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPassphraseInfoBottomSheetModel: Identifiable {
    let id = UUID()
    let actionHandler: () -> Void
}

struct OnboardingSeedPassphraseInfoBottomSheetView: View {
    let model: OnboardingSeedPassphraseInfoBottomSheetModel

    var body: some View {
        VStack(spacing: 56) {
            VStack(spacing: 30) {
                Assets.infoCircle36.image
                    .foregroundStyle(Colors.Text.accent)
                    .padding(.top, 50)

                VStack(spacing: 10) {
                    Text(Localization.commonPassphrase)
                        .style(Fonts.Regular.title1, color: Colors.Text.primary1)

                    Text(Localization.onboardingBottomSheetPassphraseDescription)
                        .multilineTextAlignment(.center)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }
                .padding(.horizontal, 34)
            }

            MainButton(title: Localization.commonOk) {
                model.actionHandler()
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 6)
    }
}
