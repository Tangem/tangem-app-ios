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
    typealias OnPullToRefresh = OnRefresh

    private enum ProposedHeaderState {
        case collapsed
        case expanded
    }

    private let data: Data
    private let idProvider: KeyPath<(Data.Index, Data.Element), ID>
    private let headerFactory: HeaderFactory
    private let contentFactory: ContentFactory
    private let onPullToRefresh: OnPullToRefresh?

    @Binding private var selectedIndex: Int
    @State private var previouslySelectedIndex: Int

    @GestureState private var nextIndexToSelect: Int?
    @GestureState private var hasNextIndexToSelect = true

    @GestureState private var currentHorizontalTranslation: CGFloat = .zero

    @State private var cumulativeHorizontalTranslation: CGFloat = .zero

    /// - Warning: Won't be reset back to 0 after successful (non-cancelled) page switch, use with caution.
    @State private var pageSwitchProgress: CGFloat = .zero

    /// Different headers for different pages are expected to have the same height (otherwise visual glitches may occur).
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
    private var isHorizontalScrollDisabled = false

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
            makeScrollView(with: proxy)
                .onAppear(perform: scrollDetector.startDetectingScroll)
                .onDisappear(perform: scrollDetector.stopDetectingScroll)
                .onAppear {
                    // `DispatchQueue.main.async` used here to allow publishing changes during view updates
                    DispatchQueue.main.async {
                        // Applying initial view's state based on the initial value of `selectedIndex`
                        cumulativeHorizontalTranslation = -CGFloat(selectedIndex) * proxy.size.width
                    }
                }
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
        @ViewBuilder contentFactory: @escaping ContentFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.data = data
        self.idProvider = idProvider
        _selectedIndex = selectedIndex
        _previouslySelectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        self.headerFactory = headerFactory
        self.contentFactory = contentFactory
        self.onPullToRefresh = onPullToRefresh
    }

    private func makeHeader(with proxy: GeometryProxy) -> some View {
        // TODO: Andrey Fedorov - Migrate to LazyHStack (IOS-3771)
        HStack(spacing: Constants.headerInteritemSpacing) {
            ForEach(data.indexed(), id: idProvider) { index, element in
                headerFactory(element)
                    .frame(width: max(proxy.size.width - Constants.headerItemHorizontalOffset * 2.0, 0.0))
                    .readGeometry(\.size.height, bindTo: $headerHeight)
            }
        }
        // This offset translates the page based on swipe
        .offset(x: currentHorizontalTranslation)
        // This offset determines which page is shown
        .offset(x: cumulativeHorizontalTranslation)
        // This offset is responsible for the next/previous cell peek
        .offset(x: headerItemPeekHorizontalOffset)
        .infinityFrame(axis: .horizontal, alignment: .topLeading)
    }

    @ViewBuilder
    private func makeScrollView(with geometryProxy: GeometryProxy) -> some View {
        ScrollViewReader { scrollViewProxy in
            Group {
                if let onPullToRefresh = onPullToRefresh {
                    RefreshableScrollView(onRefresh: onPullToRefresh) {
                        makeContent(with: geometryProxy)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        makeContent(with: geometryProxy)
                    }
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

    @ViewBuilder
    private func makeContent(with geometryProxy: GeometryProxy) -> some View {
        // ScrollView inserts default spacing between its content views.
        // Wrapping content into `VStack` prevents it.
        VStack(spacing: 0.0) {
            VStack(spacing: 0.0) {
                // This spacer acts as an auto scroll target when the header is expanded
                Spacer(minLength: Constants.headerVerticalPadding)
                    .fixedSize()
                    .id(expandedHeaderScrollTargetIdentifier)

                makeHeader(with: geometryProxy)
                    .gesture(
                        makeDragGesture(with: geometryProxy),
                        including: isHorizontalScrollDisabled ? .subviews : .all
                    )

                // This spacer is used to maintain `Constants.headerAdditionalSpacingHeight` (value
                // derived from mockups) spacing between the bottom edge of the navigation bar and
                // the top edge of the `content` part of a particular page when the header is collapsed
                Spacer(minLength: Constants.headerAdditionalSpacingHeight)
                    .fixedSize()

                // This spacer acts as an auto scroll target when the header is collapsed
                Spacer(minLength: Constants.headerVerticalPadding)
                    .fixedSize()
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
                    pageSwitchProgress = (newIndex == selectedIndex) ? 0.0 : 1.0
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

        guard 0.0 <= yOffset, yOffset < headerHeight else { return }

        let headerAutoScrollRatio: CGFloat
        if proposedHeaderState == .collapsed {
            headerAutoScrollRatio = Constants.headerAutoScrollThresholdRatio
        } else {
            headerAutoScrollRatio = 1.0 - Constants.headerAutoScrollThresholdRatio
        }

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
        @ViewBuilder contentFactory: @escaping ContentFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.init(
            data: data,
            id: \.1.id,
            selectedIndex: selectedIndex,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            onPullToRefresh: onPullToRefresh
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

    func horizontalScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isHorizontalScrollDisabled = disabled }
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
    private struct PreviewConfig: Identifiable {
        let id = UUID()
        let initiallySelectedIndex: Int
        let hasPullToRefresh: Bool
    }

    private struct ContainerView: View {
        init(
            previewConfig: PreviewConfig
        ) {
            _selectedIndex = .init(initialValue: previewConfig.initiallySelectedIndex)
            self.hasPullToRefresh = previewConfig.hasPullToRefresh
        }

        @StateObject private var previewProvider = CardsInfoPagerPreviewProvider()
        @State private var isHorizontalScrollDisabled = false
        @State private var selectedIndex: Int
        private let hasPullToRefresh: Bool

        private var onPullToRefresh: OnRefresh? {
            guard hasPullToRefresh else { return nil }

            return  { completionHandler in
                AppLog.shared.debug("Starting pull to refresh at \(CACurrentMediaTime())")
                isHorizontalScrollDisabled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    AppLog.shared.debug("Finishing pull to refresh at \(CACurrentMediaTime())")
                    completionHandler()
                    isHorizontalScrollDisabled = false
                }
            }
        }

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
                        },
                        onPullToRefresh: onPullToRefresh
                    )
                    .pageSwitchThreshold(0.4)
                    .contentViewVerticalOffset(64.0)
                    .horizontalScrollDisabled(isHorizontalScrollDisabled)
                    .navigationTitle("CardsInfoPagerView")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private struct CardsInfoPagerPreview: View {
        var previewConfigs: [PreviewConfig] {
            return [
                PreviewConfig(initiallySelectedIndex: 0, hasPullToRefresh: true),
                PreviewConfig(initiallySelectedIndex: 2, hasPullToRefresh: false),
            ]
        }

        var body: some View {
            ForEach(previewConfigs) { previewConfig in
                ContainerView(previewConfig: previewConfig)
            }
        }
    }

    static var previews: some View {
        CardsInfoPagerPreview()
    }
}
