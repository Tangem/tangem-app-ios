//
//  Web3StoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct Web3StoryPage: View {
    @Binding var progress: Double
    @Binding var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    private let numberOfRows = 6
    private let numberOfRowImages = 6

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 16) {
                Text(Localization.storyWeb3Title)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)

                Text(Localization.storyWeb3Description)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)

            Color.clear
                .background(
                    VStack {
                        Group {
                            ForEach(0 ..< numberOfRows, id: \.self) { index in
                                let odd = (index % 2 == 0)
                                Image("dapps-\(index % numberOfRowImages)")
                                    .offset(x: odd ? 50 : 0)
                                    .offset(x: -75 * Double(numberOfRows - index) / Double(numberOfRows) * progress, y: 0)
                            }
                        }
                        .frame(height: 63)
                    }
                    .offset(x: 0, y: 30),

                    alignment: .top
                )
                .clipped()
                .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            LinearGradient(colors: [.white.opacity(0), Color("tangem_story_background")], startPoint: .top, endPoint: .bottom)
                                .frame(height: geometry.size.height / 4)
                        }
                    }
                )

            StoriesBottomButtons(scanColorStyle: .primary, orderColorStyle: .secondary, isScanning: $isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Web3StoryPage_Previews: PreviewProvider {
    static var previews: some View {
        Web3StoryPage(progress: .constant(1), isScanning: .constant(false)) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
