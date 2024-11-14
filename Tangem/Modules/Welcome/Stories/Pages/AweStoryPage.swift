//
//  AweStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AweStoryPage: View {
    var progress: Double
    var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 12) {
                Text(Localization.storyAweTitle)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .minorDelay)

                Text(Localization.storyAweDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .minorDelay)
            }
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            ZStack(alignment: .bottom) {
                Color.clear
                    .background(
                        Assets.Stories.tangemMain.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .fixedSize(horizontal: false, vertical: true),

                        alignment: .top
                    )
                    .overlay(
                        LinearGradient(colors: [
                            .clear,
                            Colors.Old.tangemStoryBackground,
                            Colors.Old.tangemStoryBackground,
                        ], startPoint: .top, endPoint: .bottom)
                            .frame(height: 100),
                        alignment: .bottom
                    )

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Old.tangemStoryBackground.edgesIgnoringSafeArea(.all))
    }
}

struct AweStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        AweStoryPage(progress: 1, isScanning: false) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}
