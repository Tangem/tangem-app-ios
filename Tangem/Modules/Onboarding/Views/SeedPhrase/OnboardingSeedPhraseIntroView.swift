//
//  OnboardingSeedPhraseIntroView.swift
//  Tangem
//
//  Created by Andrew Son on 07/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPhraseIntroView: View {
    let readMoreAction: () -> Void
    let generateSeedAction: () -> Void
    let importWalletAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Assets.Onboarding.listWithPencil.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.onboardingSeedPhraseIntroLegacy)
                .style(
                    Fonts.Bold.caption2,
                    color: Colors.Icon.warning
                )
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Colors.Icon.warning.opacity(0.12))
                .cornerRadiusContinuous(8)
                .padding(.top, 28)

            Text(Localization.onboardingSeedIntroTitle)
                .style(
                    Fonts.Bold.title1,
                    color: Colors.Text.primary1
                )
                .padding(.top, 14)

            Text(Localization.onboardingSeedIntroMessage)
                .style(
                    Fonts.Regular.callout,
                    color: Colors.Text.secondary
                )
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 44)
                .padding(.top, 14)

            Button(action: readMoreAction) {
                HStack {
                    Assets.arrowRightUpMini.image
                        .foregroundColor(Colors.Icon.primary1)

                    Text(Localization.onboardingSeedButtonReadMore)
                        .style(
                            Fonts.Bold.subheadline,
                            color: Colors.Text.primary1
                        )
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Colors.Field.focused, lineWidth: 1)
                )
            }
            .padding(.top, 26)

            Spacer()

            bottomButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    var bottomButtons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.onboardingSeedIntroButtonGenerate,
                style: .secondary,
                action: generateSeedAction
            )

            MainButton(
                title: Localization.onboardingSeedIntroButtonImport,
                style: .secondary,
                action: importWalletAction
            )
        }
    }
}

struct OnboardingSeedPhrasePreview: PreviewProvider {
    static var previews: some View {
        OnboardingSeedPhraseIntroView(
            readMoreAction: {},
            generateSeedAction: {},
            importWalletAction: {}
        )
    }
}
