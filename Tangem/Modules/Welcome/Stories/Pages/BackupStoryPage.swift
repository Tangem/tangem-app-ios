//
//  BackupStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackupStoryPage: View {
    var progress: Double
    var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    private let descriptionFontSize: CGFloat = 16

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 14) {
                Text(Localization.storyBackupTitle)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)

                Text(Localization.storyBackupDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            GeometryReader { geometry in
                Color.clear
                    .background(
                        // Bottom card
                        Assets.Stories.tangemCard.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.7 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(-40 + 10 * progress),
                                axis: (0.2 + progress / 3, 0.1 + progress / 3, 0.4 + progress / 3),
                                perspective: 0
                            )
                            .offset(x: 0.25 * geometry.size.width, y: 0.3 * geometry.size.width)
                            .offset(x: -30 * progress, y: -30 * progress)
                            .scaleEffect(1 + 0.2 * progress)
                    )
                    .background(
                        // Top left
                        Assets.Stories.tangemCard.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.65 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(50 - progress * 15),
                                axis: (0.15 + progress / 4, 0.3 + progress / 4, 0.4 + progress / 4),
                                perspective: 0
                            )
                            .offset(x: -0.45 * geometry.size.width, y: -0.2 * geometry.size.width)
                            .offset(x: 20 * progress, y: 10 * progress)
                    )
                    .background(
                        // Top right
                        Assets.Stories.tangemCard.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.5 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(50 + 20 * progress),
                                axis: (0.3 + progress / 9, 0.0 + progress / 9, -0.5 + progress / 9),
                                perspective: 0
                            )
                            .offset(x: 0.3 * geometry.size.width, y: -0.3 * geometry.size.width)
                            .offset(x: -10 * progress, y: -5 * progress)
                            .scaleEffect(1 - 0.2 * progress)
                    )
            }

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
        .background(Colors.Old.tangemStoryBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BackupStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        BackupStoryPage(progress: 1, isScanning: false) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
