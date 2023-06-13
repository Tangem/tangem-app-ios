//
//  CardsInfoPagerView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerView<
    Data, ID, Header, Body
>: View where Data: RandomAccessCollection, ID: Hashable, Header: View, Body: View, Data.Index == Int {
    typealias HeaderFactory = (_ element: Data.Element) -> Header
    typealias ContentFactory = (_ element: Data.Element, _ scrollViewConnector: CardsInfoPagerScrollViewConnector) -> Body

    private let data: Data
    private let idProvider: KeyPath<(Data.Index, Data.Element), ID>
    private let headerFactory: HeaderFactory
    private let contentFactory: ContentFactory

    @Binding private var selectedIndex: Int

    @GestureState private var nextIndexToSelect: Int?
    @GestureState private var hasNextIndexToSelect = true
    @GestureState private var horizontalTranslation: CGFloat = .zero

    /// - Warning: Won't be reset back to 0 after successful (non-cancelled) page switch, use with caution.
    @State private var pageSwitchProgress: CGFloat = .zero
    @State private var headerHeight: CGFloat = .zero
    @State private var verticalContentOffset: CGPoint = .zero

    private var contentViewVerticalOffset: CGFloat = Constants.contentViewVerticalOffset
    private var pageSwitchThreshold: CGFloat = Constants.pageSwitchThreshold
    private var pageSwitchAnimation: Animation = Constants.pageSwitchAnimation

    private var lowerBound: Int { 0 }
    private var upperBound: Int { data.count - 1 }

    private var headerItemPeekHorizontalOffset: CGFloat {
        var offset = 0.0
        // Semantically, this is the same as `UICollectionViewFlowLayout.sectionInset` from UIKit
        offset += Constants.headerItemHorizontalOffset * CGFloat(selectedIndex + 1)
        // Semantically, this is the same as `UICollectionViewFlowLayout.minimumInteritemSpacing` from UIKit
        offset += Constants.headerInteritemSpacing * CGFloat(selectedIndex)
        return offset
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                makeContent(with: proxy)

                makeHeader(with: proxy)
                    .gesture(makeDragGesture(with: proxy))
            }
            .animation(pageSwitchAnimation, value: horizontalTranslation)
            .environment(\.cardsInfoPageHeaderPlaceholderHeight, headerHeight)
        }
    }

    init(
        data: Data,
        id idProvider: KeyPath<(Data.Index, Data.Element), ID>,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory
    ) {
        self.data = data
        self.idProvider = idProvider
        _selectedIndex = selectedIndex
        self.headerFactory = headerFactory
        self.contentFactory = contentFactory
    }

    private func makeHeader(with proxy: GeometryProxy) -> some View {
        // TODO: Andrey Fedorov - Migrate to LazyHStack (IOS-3771)
        HStack(spacing: Constants.headerInteritemSpacing) {
            ForEach(data.indexed(), id: idProvider) { index, element in
                headerFactory(element)
                    .frame(width: proxy.size.width - Constants.headerItemHorizontalOffset * 2.0)
                    .readSize { headerHeight = $0.height } // All headers are expected to have the same height
            }
        }
        // The first offset determines which page is shown
        .offset(x: -CGFloat(selectedIndex) * proxy.size.width)
        // The second offset translates the page based on swipe
        .offset(x: horizontalTranslation)
        // The third offset is responsible for the next/previous cell peek
        .offset(x: headerItemPeekHorizontalOffset)
        // This offset is responsible for the header stickiness
        .offset(y: -verticalContentOffset.y)
        .infinityFrame(alignment: .topLeading)
    }

    private func makeContent(with proxy: GeometryProxy) -> some View {
        // TODO: Andrey Fedorov - Migrate to LazyHStack (IOS-3771)
        ZStack(alignment: .topLeading) {
            let currentPageIndex = nextIndexToSelect ?? selectedIndex
            ForEach(data.indexed(), id: idProvider) { index, element in
                let scrollViewConnector = CardsInfoPagerScrollViewConnector(
                    headerPlaceholderView: CardsInfoPageHeaderPlaceholderView(),
                    contentOffsetBinding: $verticalContentOffset
                )
                contentFactory(element, scrollViewConnector)
                    .hidden(index != currentPageIndex)
            }
        }
        .frame(size: proxy.size)
        .modifier(
            BodyAnimationModifier(
                progress: pageSwitchProgress,
                verticalOffset: contentViewVerticalOffset,
                hasNextIndexToSelect: hasNextIndexToSelect
            )
        )
    }

    private func makeDragGesture(with proxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($horizontalTranslation) { value, state, _ in
                state = value.translation.width
            }
            .updating($nextIndexToSelect) { value, state, _ in
                // The `content` part of the page must be updated exactly in the middle of the
                // current gesture/animation, therefore `nextPageThreshold` equals 0.5 here
                state = nextIndexToSelectFiltered(
                    translation: value.translation.width,
                    totalWidth: proxy.size.width,
                    nextPageThreshold: 0.5
                )
            }
            .updating($hasNextIndexToSelect) { value, state, _ in
                // The `content` part of the page must be updated exactly in the middle of the
                // current gesture/animation, therefore `nextPageThreshold` equals 0.5 here
                state = nextIndexToSelectFiltered(
                    translation: value.translation.width,
                    totalWidth: proxy.size.width,
                    nextPageThreshold: 0.5
                ) != nil
            }
            .onChanged { value in
                pageSwitchProgress = abs(value.translation.width / proxy.size.width)
            }
            .onEnded { value in
                let newIndex = nextIndexToSelectClamped(
                    translation: value.translation.width,
                    totalWidth: proxy.size.width,
                    nextPageThreshold: pageSwitchThreshold
                )
                pageSwitchProgress = newIndex == selectedIndex ? 0.0 : 1.0
                selectedIndex = newIndex
            }
    }

    private func nextIndexToSelectClamped(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int {
        let nextIndex = nextIndexToSelect(
            translation: translation,
            totalWidth: totalWidth,
            nextPageThreshold: nextPageThreshold
        )
        return clamp(nextIndex, min: lowerBound, max: upperBound)
    }

    private func nextIndexToSelectFiltered(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int? {
        let nextIndex = nextIndexToSelect(
            translation: translation,
            totalWidth: totalWidth,
            nextPageThreshold: nextPageThreshold
        )
        return lowerBound ... upperBound ~= nextIndex ? nextIndex : nil
    }

    private func nextIndexToSelect(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int {
        let gestureProgress = translation / (totalWidth * nextPageThreshold * 2.0)
        let indexDiff = Int(gestureProgress.rounded())
        return selectedIndex - indexDiff
    }
}

// MARK: - Convenience extensions

extension CardsInfoPagerView where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        data: Data,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory
    ) {
        self.init(
            data: data,
            id: \.1.id,
            selectedIndex: selectedIndex,
            headerFactory: headerFactory,
            contentFactory: contentFactory
        )
    }
}

// MARK: - Setupable protocol conformance

extension CardsInfoPagerView: Setupable {
    func pageSwitchAnimation(_ animation: Animation) -> Self {
        map { $0.pageSwitchAnimation = animation }
    }

    func pageSwitchThreshold(_ threshold: CGFloat) -> Self {
        map { $0.pageSwitchThreshold = threshold }
    }

    /// Maximum vertical offset for the `content` part of the page during
    /// gesture-driven or animation-driven page switch
    func contentViewVerticalOffset(_ offset: CGFloat) -> Self {
        map { $0.contentViewVerticalOffset = offset }
    }
}

// MARK: - Auxiliary types

/// A dumb wrapper to hide a concrete type of header placeholder view.
struct CardsInfoPagerScrollViewConnector {
    let contentOffsetBinding: Binding<CGPoint>
    var placeholderView: some View { headerPlaceholderView }

    private let headerPlaceholderView: CardsInfoPageHeaderPlaceholderView

    fileprivate init(
        headerPlaceholderView: CardsInfoPageHeaderPlaceholderView,
        contentOffsetBinding: Binding<CGPoint>
    ) {
        self.headerPlaceholderView = headerPlaceholderView
        self.contentOffsetBinding = contentOffsetBinding
    }
}

private struct BodyAnimationModifier: Animatable, ViewModifier {
    var progress: CGFloat
    let verticalOffset: CGFloat
    let hasNextIndexToSelect: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let ratio = !hasNextIndexToSelect && progress > 0.5
            ? 1.0
            : sin(.pi * progress)

        return content
            .opacity(1.0 - Double(ratio))
            .offset(y: verticalOffset * ratio)
    }
}

// MARK: - Constants

private extension CardsInfoPagerView {
    private enum Constants {
        static var headerInteritemSpacing: CGFloat { 8.0 }
        static var headerItemHorizontalOffset: CGFloat { headerInteritemSpacing * 2.0 }
        static var contentViewVerticalOffset: CGFloat { 44.0 }
        static var pageSwitchThreshold: CGFloat { 0.5 }
        static var pageSwitchAnimation: Animation { .interactiveSpring(response: 0.30) }
    }
}

// MARK: - Previews

struct CardsInfoPagerView_Previews: PreviewProvider {
    private struct CardsInfoPagerPreview: View {
        @ObservedObject private var previewProvider = CardsInfoPagerPreviewProvider()

        @State private var selectedIndex = 0

        var body: some View {
            ZStack {
                Colors.Background.secondary
                    .ignoresSafeArea()

                CardsInfoPagerView(
                    data: previewProvider.pages,
                    selectedIndex: $selectedIndex,
                    headerFactory: { pageViewModel in
                        MultiWalletCardHeaderView(viewModel: pageViewModel.header)
                            .cornerRadius(14.0)
                    },
                    contentFactory: { pageViewModel, scrollViewConnector in
                        CardInfoPagePreviewView(
                            viewModel: pageViewModel,
                            scrollViewConnector: scrollViewConnector
                        )
                    }
                )
                .pageSwitchThreshold(0.4)
                .contentViewVerticalOffset(64.0)
            }
        }
    }

    static var previews: some View {
        CardsInfoPagerPreview()
    }
}
