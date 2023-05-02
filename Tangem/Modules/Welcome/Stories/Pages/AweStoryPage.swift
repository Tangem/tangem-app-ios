//
//  AweStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AweStoryPage: View {
    @Binding var progress: Double
    @Binding var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 12) {
                Text(Localization.storyAweTitle)
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .minorDelay)

                Text(Localization.storyAweDescription)
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .minorDelay)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Assets.Stories.coinShower.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    LinearGradient(stops: [
                        Gradient.Stop(color: Color("tangem_story_background").opacity(0), location: 0.5),
                        Gradient.Stop(color: Color("tangem_story_background"), location: 1),
                    ], startPoint: .top, endPoint: .bottom)
                        .frame(minWidth: 1000)
                )
                .storyImageAppearanceModifier(
                    progress: progress,
                    start: 0,
                    fastMovementStartCoefficient: 1,
                    fastMovementSpeedCoefficient: -45,
                    fastMovementEnd: 0.15,
                    slowMovementSpeedCoefficient: 0.15
                )

            StoriesBottomButtons(scanColorStyle: .primary, orderColorStyle: .secondary, isScanning: $isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
    }
}

struct AweStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        AweStoryPage(progress: .constant(1), isScanning: .constant(false)) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
            .environment(\.colorScheme, .dark)
    }
}
