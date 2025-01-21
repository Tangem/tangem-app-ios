//
//  FanStackCalculator.swift
//  Tangem
//
//  Created by Andrew Son on 23.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct FanStackCalculatorSettings {
    let cardsSize: CGSize
    let topCardRotation: Double
    let cardRotationStep: Double
    let topCardOffset: CGSize
    let cardOffsetStep: CGSize
    let scaleStep: CGFloat
    let numberOfCards: Int

    static var defaultSettings: FanStackCalculatorSettings {
        .init(
            cardsSize: .init(width: 315, height: 198),
            topCardRotation: 3,
            cardRotationStep: -10,
            topCardOffset: .init(width: 0, height: 45),
            cardOffsetStep: .init(width: 2, height: -28),
            scaleStep: 0.07,
            numberOfCards: 3
        )
    }
}

struct FanStackCalculator {
    private let maxZIndex: Double = 100

    private var containerSize: CGSize = .zero
    private var cardsSettings: [CardAnimSettings] = []
    private var settings: FanStackCalculatorSettings = .defaultSettings

    func settingsForCard(at index: Int) -> CardAnimSettings {
        guard index < cardsSettings.count, index >= 0 else {
            return .zero
        }

        return cardsSettings[index]
    }

    mutating func setup(for container: CGSize, with settings: FanStackCalculatorSettings) {
        containerSize = container
        self.settings = settings
        populateSettings()
    }

    private mutating func populateSettings() {
        cardsSettings = []
        for i in 0 ..< settings.numberOfCards {
            cardsSettings.append(cardInStackSettings(at: i))
        }
    }

    private func cardInStackSettings(at index: Int) -> CardAnimSettings {
        let floatIndex = CGFloat(index)
        let doubleIndex = Double(index)
        let heightOffset: CGFloat = settings.cardOffsetStep.height * floatIndex + settings.topCardOffset.height
        let widthOffset: CGFloat = settings.cardOffsetStep.width * floatIndex + settings.topCardOffset.width
        let rotation: Double = settings.topCardRotation + settings.cardRotationStep * doubleIndex
        let scale = settings.scaleStep * floatIndex
        let zIndex: Double = maxZIndex - doubleIndex

        return .init(
            frame: settings.cardsSize,
            offset: .init(width: widthOffset, height: heightOffset),
            scale: 1.0 - scale,
            opacity: 1.0,
            zIndex: zIndex,
            rotationAngle: .init(degrees: rotation),
            animType: .linear,
            animDuration: 0.3
        )
    }
}

class FanStackPreviewModel: ObservableObject {
    @Published var firstSettings: AnimatedViewSettings = .zero
    @Published var secondSettings: AnimatedViewSettings = .zero
    @Published var thirdSettings: AnimatedViewSettings = .zero
    @Published var fourthSettings: AnimatedViewSettings = .zero

    var calc = FanStackCalculator()

    func setupContainer(with size: CGSize) {
        calc.setup(
            for: size,
            with: .defaultSettings
        )
        firstSettings = .init(targetSettings: calc.settingsForCard(at: 0), intermediateSettings: nil)
        secondSettings = .init(targetSettings: calc.settingsForCard(at: 1), intermediateSettings: nil)
        thirdSettings = .init(targetSettings: calc.settingsForCard(at: 2), intermediateSettings: nil)
        fourthSettings = .init(targetSettings: calc.settingsForCard(at: 3), intermediateSettings: nil)
    }
}

struct FanStackView: View {
    @ObservedObject var model: FanStackPreviewModel = .init()

    private let image = Assets.Onboarding.walletCard.image

    var body: some View {
        VStack {
            GeometryReader { geom in
                ZStack {
                    AnimatedView(settings: model.$firstSettings) {
                        OnboardingCardView(
                            placeholderCardType: .dark,
                            cardImage: image,
                            cardScanned: true
                        )
                    }

                    AnimatedView(settings: model.$secondSettings) {
                        OnboardingCardView(
                            placeholderCardType: .dark,
                            cardImage: image,
                            cardScanned: true
                        )
                        .opacity(0.2)
                    }

                    AnimatedView(settings: model.$thirdSettings) {
                        OnboardingCardView(
                            placeholderCardType: .dark,
                            cardImage: image,
                            cardScanned: true
                        )
                        .opacity(0.2)
                    }
                    AnimatedView(settings: model.$fourthSettings) {
                        OnboardingCardView(
                            placeholderCardType: .dark,
                            cardImage: image,
                            cardScanned: true
                        )
                        .opacity(0.2)
                    }
                }
                .position(x: geom.size.width / 2, y: geom.size.height / 2)
            }
            .readGeometry(\.size) { size in
                model.setupContainer(with: size)
            }
            Spacer()
                .frame(size: .init(width: 100, height: 297))
        }
    }
}

struct FanStackView_Previews: PreviewProvider {
    static var previews: some View {
        FanStackView()
    }
}
