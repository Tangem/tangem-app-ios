//
//  CardStackAnimator.swift
//  Tangem
//
//  Created by Andrew Son on 01.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSwiftUIUtils

struct CardsStackAnimatorSettings {
    let topCardSize: CGSize
    let topCardOffset: CGSize
    let cardsVerticalOffset: CGFloat
    let scaleStep: CGFloat
    let opacityStep: Double
    var numberOfCards: Int
    var maxCardsInStack: Int

    static var zero: CardsStackAnimatorSettings {
        .init(
            topCardSize: .zero,
            topCardOffset: .zero,
            cardsVerticalOffset: 0,
            scaleStep: 0,
            opacityStep: 0,
            numberOfCards: 2,
            maxCardsInStack: 2
        )
    }
}

enum AnimType: Equatable {
    case `default`
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case noAnim

    func animation(with duration: Double?) -> Animation? {
        guard let duration = duration else {
            switch self {
            case .default: return .default
            case .linear: return .linear
            case .easeIn: return .easeIn
            case .easeOut: return .easeOut
            case .easeInOut: return .easeInOut
            case .noAnim: return nil
            }
        }

        switch self {
        case .default: return .default
        case .linear: return .linear(duration: duration)
        case .easeIn: return .easeIn(duration: duration)
        case .easeOut: return .easeOut(duration: duration)
        case .easeInOut: return .easeInOut(duration: duration)
        case .noAnim: return nil
        }
    }
}

struct CardAnimSettings: Equatable {
    var frame: CGSize
    var offset: CGSize
    var scale: CGFloat
    var opacity: Double
    var zIndex: Double
    var rotationAngle: Angle

    var animType: AnimType = .default
    var animDuration: Double = 0.3

    var animation: Animation? {
        animType.animation(with: animDuration)
    }

    static var zero: CardAnimSettings {
        .init(
            frame: .zero,
            offset: .zero,
            scale: 0,
            opacity: 0,
            zIndex: 0,
            rotationAngle: .zero
        )
    }

    @ViewBuilder
    func applyAnim<Content: View>(to view: Content) -> some View {
        applySettings(to: view)
            .animation(animation)
    }

    @ViewBuilder
    func applySettings<Content: View>(to view: Content) -> some View {
        view
            .frame(size: frame)
            .rotationEffect(rotationAngle)
            .scaleEffect(scale)
            .offset(offset)
            .opacity(opacity)
            .zIndex(zIndex)
    }
}

struct CardStackAnimator<Card: View>: View {
    let cards: [Card]
    let namespace: Namespace.ID
    let settings: CardsStackAnimatorSettings
    let currentCardIndexPublisher: Published<Int>.Publisher

    @State private var size: CGSize = .zero
    @State private var selectedIndex: Int = 0
    @State private var hiddenIndex: CGFloat = -1

    private let maxZIndex: Double = 100

    var body: some View {
        GeometryReader { geom in
            ZStack {
                ForEach(0 ..< cards.count, id: \.self) { index in
                    modify(cards[index], at: index)
                        .onAnimationCompleted(for: hiddenIndex) {
                            guard hiddenIndex == CGFloat(index) else { return }

                            withAnimation(.linear(duration: 0.35)) {
                                hiddenIndex = -1
                            }
                        }
                }
            }
            .position(x: geom.size.width / 2, y: geom.size.height / 2 + 50)
            .readGeometry(\.size, bindTo: $size)
        }
        .onReceive(currentCardIndexPublisher, perform: { newCardIndex in
            guard selectedIndex != newCardIndex else { return }

            withAnimation(.linear(duration: 0.4)) {
                hiddenIndex = CGFloat(selectedIndex)
                selectedIndex = min(cards.count - 1, max(newCardIndex, 0))
            }
        })
    }

    @ViewBuilder
    private func modify(_ view: Card, at index: Int) -> some View {
        let delta = index - selectedIndex
        let cardIndex = selectedIndex > index ? cards.count + delta : delta
        let settings: CardAnimSettings = CGFloat(index) == hiddenIndex ?
            prehideAnimSettings(for: cardIndex) :
            cardInStackSettings(at: cardIndex)
        view
            .matchedGeometryEffect(id: "card\(index)", in: namespace)
            .frame(size: settings.frame)
            .rotationEffect(settings.rotationAngle)
            .scaleEffect(settings.scale)
            .offset(settings.offset)
            .opacity(settings.opacity)
            .zIndex(settings.zIndex)
    }

    private func prehideAnimSettings(for index: Int) -> CardAnimSettings {
        let settings = cardInStackSettings(at: index)
        let targetFrameHeight = settings.frame.height

        return .init(
            frame: settings.frame,
            offset: .init(width: 0, height: -(settings.frame.height / 2 + targetFrameHeight / 2) - 10),
            scale: 1.0,
            opacity: 1.0,
            zIndex: maxZIndex + 100,
            rotationAngle: Angle(degrees: 0)
        )
    }

    private func cardInStackSettings(at index: Int) -> CardAnimSettings {
        let floatIndex = CGFloat(index)
        let doubleIndex = Double(index)
        let offset: CGFloat = settings.cardsVerticalOffset * 2 * floatIndex
        let scale: CGFloat = max(1 - settings.scaleStep * floatIndex, 0)
        let opacity: Double = max(1 - settings.opacityStep * doubleIndex, 0)
        let zIndex: Double = maxZIndex - Double(index)

        return .init(
            frame: settings.topCardSize,
            offset: .init(width: 0, height: offset),
            scale: scale,
            opacity: opacity,
            zIndex: zIndex,
            rotationAngle: .zero
        )
    }
}

class CardStackAnimatorPreviewModel: ObservableObject {
    enum Content {
        case twins
        case backup(numberOfCards: Int)
    }

    @Published var currentCardIndex: Int = 0
    @Published var sliderIndex: Double = 0

    let content: Content

    var maxIndex: Int {
        switch content {
        case .twins: return 1
        case .backup(let numberOfCards): return numberOfCards - 1
        }
    }

    init(content: Content) {
        self.content = content
    }
}

struct CardStackAnimatorPreview: View {
    @ObservedObject var viewModel: CardStackAnimatorPreviewModel = .init(content: .backup(numberOfCards: 3))

    @Namespace var ns

    var animatorSettings: CardsStackAnimatorSettings {
        .init(
            topCardSize: .init(width: 315, height: 184),
            topCardOffset: .zero,
            cardsVerticalOffset: 17,
            scaleStep: 0.1,
            opacityStep: 0.2,
            numberOfCards: 3,
            maxCardsInStack: 3
        )
    }

    @ViewBuilder
    var animator: some View {
        switch viewModel.content {
        case .twins:
            CardStackAnimator(
                cards: [
                    OnboardingCardView(
                        placeholderCardType: .dark,
                        cardImage: nil,
                        cardScanned: false
                    ),
                    OnboardingCardView(
                        placeholderCardType: .light,
                        cardImage: nil,
                        cardScanned: false
                    ),
                ], namespace: ns,
                settings: animatorSettings,
                currentCardIndexPublisher: viewModel.$currentCardIndex
            )
        case .backup(let numberOfCards):
            CardStackAnimator(
                cards: (0 ..< numberOfCards)
                    .map { index in
                        OnboardingCardView(
                            placeholderCardType: .dark,
                            cardImage: nil,
                            cardScanned: false
                        )
                    }, namespace: ns,
                settings: animatorSettings,
                currentCardIndexPublisher: viewModel.$currentCardIndex
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            animator

            OnboardingMessagesView(
                title: "Testing animator",
                subtitle: "This is preview screen and must not be used in production. \nSelect card number:"
            ) {}
                .padding(.bottom, 50)
            HStack {
                ForEach(0 ... viewModel.maxIndex, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            viewModel.currentCardIndex = index
                        }
                    }, label: {
                        Text("\(index + 1)")
                            .frame(size: .init(width: 50, height: 50))
                    })
                    .buttonStyle(TangemButtonStyle())
                }
                Button(action: {
                    var newIndex = viewModel.currentCardIndex + 1
                    if newIndex > viewModel.maxIndex {
                        newIndex = 0
                    }
                    withAnimation {
                        viewModel.currentCardIndex = newIndex
                    }
                }, label: {
                    Text("Next")
                        .padding()
                })
                .buttonStyle(TangemButtonStyle(colorStyle: .black, font: .system(size: 20, weight: .bold)))
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 40)
    }
}

struct CardStackAnimator_Previews: PreviewProvider {
    static var previews: some View {
        CardStackAnimatorPreview(
            viewModel:
            CardStackAnimatorPreviewModel(content: .twins)
//                CardStackAnimatorPreviewModel(content: .backup(numberOfCards: 3))
        )
    }
}
