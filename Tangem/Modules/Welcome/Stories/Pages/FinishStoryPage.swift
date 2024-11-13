//
//  FinishStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct FinishStoryPage: View {
    var progress: Double
    var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 18) {
                Text(Localization.storyFinishTitle)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .minorDelay)

                Text(Localization.storyFinishDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .minorDelay)
            }
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Color.clear
                .background(
                    Assets.Stories.handWithCard.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fixedSize(horizontal: false, vertical: true)
                        .edgesIgnoringSafeArea(.bottom)
                        .overlay(
                            LinearGradient(stops: [
                                Gradient.Stop(color: Colors.Old.tangemStoryBackground.opacity(0), location: 0.7),
                                Gradient.Stop(color: Colors.Old.tangemStoryBackground, location: 1),
                            ], startPoint: .top, endPoint: .bottom)
                                .frame(minWidth: 1000)
                        ),
                    alignment: .top
                )

            Spacer()

            StoriesBottomButtons(
                scanColorStyle: .primary,
                orderColorStyle: .secondary,
                isScanning: isScanning,
                scanCard: scanCard,
                orderCard: orderCard
            )
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Old.tangemStoryBackground.edgesIgnoringSafeArea(.all))
    }
}

struct FinishStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        FinishStoryPage(progress: 1, isScanning: false) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}
