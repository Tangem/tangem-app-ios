//
//  CurrenciesStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CurrenciesStoryPage: View {
    var progress: Double
    var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void
    let searchTokens: () -> Void

    private let numberOfRows = 6
    private let numberOfRowImages = 5

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 16) {
                Text(Localization.storyCurrenciesTitle)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)

                Text(Localization.storyCurrenciesDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.center)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .padding(.horizontal, 28)
            .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .bottom) {
                Color.clear
                    .background(
                        VStack {
                            Group {
                                ForEach(0 ..< numberOfRows, id: \.self) { index in
                                    let odd = (index % 2 == 0)
                                    Image("currency-\(index % numberOfRowImages)")
                                        .offset(x: odd ? 50 : 0, y: 0)
                                        .offset(x: -75 * Double(numberOfRows - index) / Double(numberOfRows) * progress, y: 0)
                                }
                            }
                            .frame(height: 80)
                        }
                        .offset(x: 0, y: 30),

                        alignment: .top
                    )
                    .clipped()
                    .overlay(
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                LinearGradient(colors: [.clear, Colors.Old.tangemStoryBackground], startPoint: .top, endPoint: .bottom)
                                    .frame(height: geometry.size.height / 3)
                            }
                        }
                    )

                MainButton(
                    title: Localization.commonSearchTokens,
                    icon: .leading(Assets.search),
                    style: .secondary,
                    isDisabled: isScanning,
                    action: searchTokens
                )
                .padding(.horizontal, 16)
            }

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

struct CurrenciesStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        CurrenciesStoryPage(progress: 1, isScanning: false) {} orderCard: {} searchTokens: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
