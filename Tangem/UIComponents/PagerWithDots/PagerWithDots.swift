//
//  PagerWithDots.swift
//  Tangem
//
//  Created by Andrew Son on 19/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

/// Pager will take height needed for its content
struct PagerWithDots<Data, Content>: View
    where Data: RandomAccessCollection, Data.Element: Hashable, Data.Element: Identifiable, Content: View {
    let indexUpdateNotifier: PassthroughSubject<Int, Never>

    // the index currently displayed page
    @State private var currentIndex: Int = 0
    // keeps track of how much did user swipe left or right
    @GestureState private var translation: CGFloat = 0

    // the source data to render, can be a range, an array, or any other collection of Hashable
    private let data: Data
    // maps data to page views
    private let content: (Data.Element) -> Content
    private let pageWidth: CGFloat

    init(
        _ data: Data,
        indexUpdateNotifier: PassthroughSubject<Int, Never>,
        pageWidth: CGFloat,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.indexUpdateNotifier = indexUpdateNotifier
        self.pageWidth = pageWidth
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // render all the content, making sure that each page fills
                // the entire PagerView
                ForEach(data, id: \.id) { elem in
                    content(elem)
                        .frame(width: pageWidth)
                }
            }
            .frame(width: pageWidth, alignment: .leading)
            // the first offset determines which page is shown
            .offset(x: -CGFloat(currentIndex) * pageWidth)
            // the second offset translates the page based on swipe
            .offset(x: translation)
            .animation(.easeOut(duration: 0.3), value: currentIndex)
            .animation(.easeOut(duration: 0.3), value: translation)
            .gesture(
                data.count <= 1 ? nil :
                    DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        // determine how much was the page swiped to decide if the current page
                        // should change (and if it's going to be to the left or right)
                        let offset = (value.translation.width / pageWidth * 1.5).rounded()
                        let newIndex = (CGFloat(currentIndex) - offset)
                        currentIndex = min(max(Int(newIndex), 0), data.count - 1)
                        indexUpdateNotifier.send(currentIndex)
                    }
            )

            if data.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0 ..< data.count, id: \.id) { index in
                        Circle()
                            .foregroundColor((index == currentIndex) ? Colors.Icon.primary1 : Colors.Icon.informative)
                            .animation(.easeOut(duration: 0.5), value: currentIndex)
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(width: pageWidth, height: 20, alignment: .center)
            }
        }
    }
}

struct PagerWithDots_Previews: PreviewProvider {
    struct DemoData: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let message: String
        let image: ImageType
    }

    static let singlePageData: [DemoData] = [
        .init(
            title: "First page",
            message: "First page description that explains everything",
            image: Assets.referralDude
        ),
    ]

    static let multiplePagesData: [DemoData] = [
        .init(
            title: "Second page",
            message: "Second page description: 42",
            image: Assets.referralDude
        ),
        .init(
            title: "First page",
            message: "First page description that explains everything",
            image: Assets.referralDude
        ),
        .init(
            title: "Second page",
            message: "Second page description: 42",
            image: Assets.referralDude
        ),
    ]

    static let notifier: PassthroughSubject<Int, Never> = .init()

    struct PreviewView: View {
        let data: [DemoData]

        var body: some View {
            GeometryReader { proxy in
                PagerWithDots(
                    data,
                    indexUpdateNotifier: notifier,
                    pageWidth: proxy.size.width
                ) { data in
                    VStack(spacing: 16) {
                        Text(data.title)

                        data.image.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                        Text(data.message)
                    }
                }
            }
        }
    }

    static var previews: some View {
        VStack(spacing: 20) {
            PreviewView(data: singlePageData)

            PreviewView(data: multiplePagesData)
        }
    }
}
