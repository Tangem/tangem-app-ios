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
    typealias ContentFactory = (_ element: Data.Element) -> Body

    private enum ProposedHeaderState {
        case collapsed
        case expanded
    }

    private let data: Data
    private let idProvider: KeyPath<(Data.Index, Data.Element), ID>
    private let headerFactory: HeaderFactory
    private let contentFactory: ContentFactory

    @Binding private var selectedIndex: Int
    @State private var previouslySelectedIndex: Int

    @GestureState private var nextIndexToSelect: Int?
    @GestureState private var hasNextIndexToSelect = true

    @GestureState private var currentHorizontalTranslation: CGFloat = .zero

    @State private var cumulativeHorizontalTranslation: CGFloat = .zero

    /// - Warning: Won't be reset back to 0 after successful (non-cancelled) page switch, use with caution.
    @State private var pageSwitchProgress: CGFloat = .zero

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var headerHeight: CGFloat = .zero
    @State private var verticalContentOffset: CGPoint = .zero
    @State private var contentSize: CGSize = .zero
    @State private var viewportSize: CGSize = .zero

    private let scrollViewFrameCoordinateSpaceName = UUID()

    private let expandedHeaderScrollTargetIdentifier = UUID()
    private let collapsedHeaderScrollTargetIdentifier = UUID()

    @StateObject private var scrollDetector = ScrollDetector()
    @State private var proposedHeaderState: ProposedHeaderState = .expanded

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
            makeContent(with: proxy)
                .onAppear(perform: scrollDetector.startDetectingScroll)
                .onDisappear(perform: scrollDetector.stopDetectingScroll)
                .onChange(of: verticalContentOffset) { [oldValue = verticalContentOffset] newValue in
                    proposedHeaderState = oldValue.y > newValue.y ? .expanded : .collapsed
                }
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
        _previouslySelectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        self.headerFactory = headerFactory
        self.contentFactory = contentFactory
    }

    private func makeHeader(with proxy: GeometryProxy) -> some View {
        // TODO: Andrey Fedorov - Migrate to LazyHStack (IOS-3771)
        HStack(spacing: Constants.headerInteritemSpacing) {
            ForEach(data.indexed(), id: idProvider) { index, element in
                headerFactory(element)
                    .frame(width: max(proxy.size.width - Constants.headerItemHorizontalOffset * 2.0, 0.0))
                    .readGeometry(\.size.height, bindTo: $headerHeight) // All headers are expected to have the same height
            }
        }
        // This offset translates the page based on swipe
        .offset(x: currentHorizontalTranslation)
        // This offset determines which page is shown
        .offset(x: cumulativeHorizontalTranslation)
        // This offset is responsible for the next/previous cell peek
        .offset(x: headerItemPeekHorizontalOffset)
        .infinityFrame(alignment: .topLeading)
    }

    @ViewBuilder
    private func makeContent(with proxy: GeometryProxy) -> some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(showsIndicators: false) {
                // ScrollView inserts default spacing between its content views.
                // Wrapping content into `VStack` prevents it.
                VStack(spacing: 0.0) {
                    VStack(spacing: 0.0) {
                        Spacer(minLength: Constants.headerVerticalPadding)
                            .id(expandedHeaderScrollTargetIdentifier)

                        makeHeader(with: proxy)
                            .gesture(makeDragGesture(with: proxy))

                        Spacer(minLength: Constants.headerAdditionalSpacingHeight)

                        Spacer(minLength: Constants.headerVerticalPadding)
                            .id(collapsedHeaderScrollTargetIdentifier)

                        // FIXME: Andrey Fedorov - Current content page must be changed to prev/next page exactly when `pageSwitchProgress` equals 0.5 (IOS-4012)
                        contentFactory(data[selectedIndex])
                            .modifier(
                                ContentAnimationModifier(
                                    progress: pageSwitchProgress,
                                    verticalOffset: contentViewVerticalOffset,
                                    hasNextIndexToSelect: hasNextIndexToSelect
                                )
                            )
                    }
                    .readGeometry(\.size, bindTo: $contentSize)
                    .readContentOffset(
                        inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                        bindTo: $verticalContentOffset
                    )

                    CardsInfoPagerFlexibleFooterView(
                        contentSize: contentSize,
                        viewportSize: viewportSize,
                        headerTopInset: Constants.headerVerticalPadding,
                        headerHeight: headerHeight + Constants.headerAdditionalSpacingHeight
                    )
                }
            }
            .onChange(of: scrollDetector.isScrolling) { [oldValue = scrollDetector.isScrolling] newValue in
                if newValue != oldValue, !newValue {
                    performVerticalScrollIfNeeded(with: scrollViewProxy)
                }
            }
            .readGeometry(\.size, bindTo: $viewportSize)
            .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        }
    }

    private func makeDragGesture(with proxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($currentHorizontalTranslation) { value, state, _ in
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
                let totalWidth = proxy.size.width

                // Predicted translation takes the gesture's speed into account,
                // which makes page switching feel more natural.
                let predictedTranslation = value.predictedEndLocation.x - value.startLocation.x
                let newIndex = nextIndexToSelectClamped(
                    translation: predictedTranslation,
                    totalWidth: totalWidth,
                    nextPageThreshold: pageSwitchThreshold
                )

                cumulativeHorizontalTranslation += value.translation.width
                previouslySelectedIndex = selectedIndex

                withAnimation(pageSwitchAnimation) {
                    cumulativeHorizontalTranslation = -CGFloat(newIndex) * totalWidth
                    pageSwitchProgress = newIndex == selectedIndex ? 0.0 : 1.0
                    selectedIndex = newIndex
                }
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
        // The difference is clamped because we don't want to switch
        // by more than one page at a time in case of overscroll
        return selectedIndex - clamp(indexDiff, min: -1, max: 1)
    }

    func performVerticalScrollIfNeeded(with scrollViewProxy: ScrollViewProxy) {
        let yOffset = verticalContentOffset.y - Constants.headerVerticalPadding

        guard (0.0 ..< headerHeight) ~= yOffset else { return }

        let headerAutoScrollRatio = proposedHeaderState == .collapsed
            ? Constants.headerAutoScrollThresholdRatio
            : 1.0 - Constants.headerAutoScrollThresholdRatio

        withAnimation(.spring()) {
            if yOffset > headerHeight * headerAutoScrollRatio {
                scrollViewProxy.scrollTo(collapsedHeaderScrollTargetIdentifier, anchor: .top)
            } else {
                scrollViewProxy.scrollTo(expandedHeaderScrollTargetIdentifier, anchor: .top)
            }
        }
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

private struct ContentAnimationModifier: AnimatableModifier {
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
        static var headerVerticalPadding: CGFloat { 8.0 }
        static var headerAdditionalSpacingHeight: CGFloat { max(14.0 - Constants.headerVerticalPadding, 0.0) }
        static var headerAutoScrollThresholdRatio: CGFloat { 0.25 }
        static var contentViewVerticalOffset: CGFloat { 44.0 }
        static var pageSwitchThreshold: CGFloat { 0.5 }
        static var pageSwitchAnimation: Animation { .interactiveSpring(response: 0.4) }
    }
}

// MARK: - Previews

struct CardsInfoPagerView_Previews: PreviewProvider {
    private struct CardsInfoPagerPreview: View {
        @ObservedObject private var previewProvider = CardsInfoPagerPreviewProvider()

        @State private var selectedIndex = 0

        var body: some View {
            NavigationView {
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
                        contentFactory: { pageViewModel in
                            CardInfoPagePreviewView(viewModel: pageViewModel)
                        }
                    )
                    .pageSwitchThreshold(0.4)
                    .contentViewVerticalOffset(64.0)
                    .navigationTitle("CardsInfoPagerView")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    static var previews: some View {
        CardsInfoPagerPreview()
    }
}
