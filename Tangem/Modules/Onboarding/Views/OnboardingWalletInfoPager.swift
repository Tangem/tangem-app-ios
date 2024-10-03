//
//  OnboardingWalletInfoPager.swift
//  Tangem
//
//  Created by Andrew Son on 29.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

private struct PagerView<Data, Content>: View
    where Data: RandomAccessCollection, Data.Element: Hashable, Content: View {
    let indexUpdateNotifier: PassthroughSubject<Void, Never>
    // the source data to render, can be a range, an array, or any other collection of Hashable
    private let data: Data
    // the index currently displayed page
    @Binding var currentIndex: Int
    // maps data to page views
    private let content: (Data.Element) -> Content

    // keeps track of how much did user swipe left or right
    @GestureState private var translation: CGFloat = 0

    // the custom init is here to allow for @ViewBuilder for
    // defining content mapping
    init(
        _ data: Data,
        indexUpdateNotifier: PassthroughSubject<Void, Never>,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.indexUpdateNotifier = indexUpdateNotifier
        _currentIndex = currentIndex
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // render all the content, making sure that each page fills
                // the entire PagerView
                ForEach(data, id: \.self) { elem in
                    content(elem)
                        .frame(width: geometry.size.width)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
            // the first offset determines which page is shown
            .offset(x: -CGFloat(currentIndex) * geometry.size.width)
            // the second offset translates the page based on swipe
            .offset(x: translation)
            .animation(.interactiveSpring())
            .gesture(
                DragGesture().updating($translation) { value, state, _ in
                    state = value.translation.width
                }.onEnded { value in
                    // determine how much was the page swiped to decide if the current page
                    // should change (and if it's going to be to the left or right)
                    // 1.25 is the parameter that defines how much does the user need to swipe
                    // for the page to change. 1.0 would require swiping all the way to the edge
                    // of the screen to change the page.
                    let offset = value.translation.width / geometry.size.width * 2
                    let newIndex = (CGFloat(currentIndex) - offset).rounded()
                    currentIndex = min(max(Int(newIndex), 0), data.count - 1)
                    indexUpdateNotifier.send()
                }
            )
        }
    }
}

private struct PagerViewWithDots<Data, Content>: View
    where Data: RandomAccessCollection, Data.Element: Hashable, Content: View {
    @State private var currentIndex = 0
    private let data: Data
    private let animated: Bool
    private let content: (Data.Element) -> Content

    @State private var indexUpdatePublisher: PassthroughSubject<Void, Never> = .init()
    @State private var pageUpdateWork: DispatchWorkItem?

    init(
        _ data: Data,
        animated: Bool,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.animated = animated
        self.content = content
    }

    var body: some View {
        ZStack {
            // let the PagerView and the dots fill the available screen
            Color.clear
            // render the Pager View
            PagerView(data, indexUpdateNotifier: indexUpdatePublisher, currentIndex: $currentIndex, content: content)
            // the dots view
            VStack {
                Spacer() // align the dots at the bottom
                HStack(spacing: 6) {
                    ForEach(0 ..< data.count, id: \.self) { index in
                        Circle()
                            .foregroundColor((index == currentIndex) ? Colors.Old.tangemGrayDark6 : Colors.Old.tangemGrayLight5)
                            .frame(width: 10, height: 10)
                    }
                }
            }.padding()
        }
        .onReceive(indexUpdatePublisher, perform: { _ in
            pageUpdateWork?.cancel()
            pageUpdateWork = nil
            switchToNextPage()
        })
        .onAppear(perform: {
            switchToNextPage()
        })
    }

    private func switchToNextPage() {
        guard animated else { return }

        pageUpdateWork = DispatchWorkItem {
            var index = currentIndex + 1
            if index >= data.count {
                index = 0
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                currentIndex = index
            }
            switchToNextPage()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: pageUpdateWork!)
    }
}

enum TangemWalletOnboardingInfoPage: CaseIterable {
    case first
    case second
    case third
    case fourth

    var title: String {
        switch self {
        case .first: return Localization.onboardingWalletInfoTitleFirst
        case .second: return Localization.onboardingWalletInfoTitleSecond
        case .third: return Localization.onboardingWalletInfoTitleThird
        case .fourth: return Localization.onboardingWalletInfoTitleFourth
        }
    }

    var subtitle: String {
        switch self {
        case .first: return Localization.onboardingWalletInfoSubtitleFirst
        case .second: return Localization.onboardingWalletInfoSubtitleSecond
        case .third: return Localization.onboardingWalletInfoSubtitleThird
        case .fourth: return Localization.onboardingWalletInfoSubtitleFourth
        }
    }
}

struct OnboardingWalletInfoPager: View {
    let infoPages: [TangemWalletOnboardingInfoPage] = TangemWalletOnboardingInfoPage.allCases

    let animated: Bool

    var body: some View {
        PagerViewWithDots(infoPages, animated: animated) { page in
            OnboardingMessagesView(title: page.title, subtitle: page.subtitle, onTitleTapCallback: {})
                .padding(.horizontal, 40)
        }
    }
}

struct OnboardingWalletInfoPager_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingWalletInfoPager(animated: true)
    }
}
