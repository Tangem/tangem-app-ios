//
//  OnboardingSeedPhraseGenerateView.swift
//  Tangem
//
//  Created by Andrew Son on 09/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPhraseGenerateView: View {
    let words: [String]
    let continueAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.onboardingSeedGenerateTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .padding(.top, 40)

            Text(Localization.onboardingSeedGenerateMessage)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 54)
                .padding(.top, 14)

            HStack(alignment: .top, spacing: 8) {
                wordsVerticalView(indexRange: 0 ..< (words.count / 2))

                wordsVerticalView(indexRange: (words.count / 2) ..< words.count)
            }
            .padding(.top, 42)
            .padding(.horizontal, 44)

            Spacer()

            MainButton(
                title: Localization.commonContinue,
                style: .primary,
                action: continueAction
            )
            .padding(.horizontal, 16)
            .padding(.bottom, AppConstants.isSmallScreen ? 10 : 6)
        }
    }

    @ViewBuilder
    private func wordsVerticalView(indexRange: Range<Int>) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(indexRange, id: \.self) { index in
                HStack(alignment: .center, spacing: 0) {
                    Text("\(index + 1).\t")
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

                    Text("\(words[index])")
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Spacer()
                }
            }
        }
    }
}

struct OnboardingSeedPhraseGenerateView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingSeedPhraseGenerateView(
            words: ["Several", "very", "random", "words", "from", "the", "bip39", "dictionary", "for", "tangem", "wallet", "app"],
            continueAction: {}
        )
    }
}
