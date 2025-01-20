//
//  CardsInfoPagerView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSwiftUIUtils

struct CardsInfoPagerView<
    Data, ID, Header, Body, BottomOverlay
>: View where Data: RandomAccessCollection, ID: Hashable, Header: View, Body: View, BottomOverlay: View, Data.Index == Int {
    typealias HeaderFactory = (_ element: Data.Element) -> Header
    typealias ContentFactory = (_ element: Data.Element) -> Body
    typealias BottomOverlayFactory = (_ element: Data.Element, _ overlayParams: CardsInfoPagerBottomOverlayFactoryParams) -> BottomOverlay
    typealias OnPullToRefresh = OnRefresh
    typealias OnPageChange = (_ pageChangeReason: CardsInfoPageChangeReason) -> Void

    // MARK: - Dependencies

    private let data: Data
    private let idProvider: KeyPath<(Data.Index, Data.Element), ID>
    private let headerFactory: HeaderFactory
    private let contentFactory: ContentFactory
    private let bottomOverlayFactory: BottomOverlayFactory
    private let onPullToRefresh: OnPullToRefresh?

    // MARK: - Selected index

    @State private var selectedIndex: Int

    /// `External` here means 'driven from the outside' (by the consumer of this pager view).
    @Binding private var externalSelectedIndex: Int

    /// Contains previous value of the `selectedIndex` property.
    @State private var previouslySelectedIndex: Int

    /// The `content` part of the pager must be updated exactly in the middle of the active gesture/animation.
    /// Therefore, a separate property for a currently selected page index is used for the `content` part
    /// instead of the `selectedIndex` (`selectedIndex` is updated just after the drag gesture ends,
    /// whereas `content` part must be updated exactly in the middle of the current gesture/animation).
    @State private var contentSelectedIndex: Int

    private var clampedContentSelectedIndex: Int {
        return clamp(contentSelectedIndex, min: selectedIndexLowerBound, max: selectedIndexUpperBound)
    }

    @State private var scheduledContentSelectedIndexUpdate: DispatchWorkItem?

    /// Equals `true` if we a have valid next/previous index (relative to the currently selected index, `selectedIndex`)
    /// to select from the currently selected index, `false` otherwise.
    ///
    /// - Warning: This property has an undefined value if there is no active drag gesture.
    @State private var hasValidIndexToSelect = false

    private var selectedIndexLowerBound: Int { 0 }
    private var selectedIndexUpperBound: Int { data.count - 1 }

    // MARK: - Page switch progress

    /// Progress in 0...1 range, updated with animation.
    ///
    /// - Warning: Won't be reset back to 0 after a successful (non-cancelled) page switch, use with caution.
    @State private var pageSwitchProgress: CGFloat = .zero

    /// Progress in 0...1 range, updated without animation. Set at the end of the active drag gesture.
    ///
    /// - Warning: Won't be reset back to 0 after a successful (non-cancelled) page switch, use with caution.
    @State private var initialPageSwitchProgress: CGFloat = .zero

    /// Progress in 0...1 range, updated without animation. Set at the end of the active drag gesture.
    ///
    /// - Warning: Won't be reset back to 0 after a successful (non-cancelled) page switch, use with caution.
    @State private var finalPageSwitchProgress: CGFloat = .zero

    // MARK: - Horizontal scrolling

    @ObservedObject private var swipeDiscoveryAnimationTrigger: CardsInfoPagerSwipeDiscoveryAnimationTrigger
    @State private var isSwipeDiscoveryAnimationActive = false

    @GestureState private var isDraggingHorizontally = false

    @GestureState private var currentHorizontalTranslation: CGFloat = .zero
    @State private var cumulativeHorizontalTranslation: CGFloat = .zero

    private var headerItemPeekHorizontalOffset: CGFloat {
        var offset = 0.0
        // Semantically, this is the same as `UICollectionViewFlowLayout.sectionInset` from UIKit
        offset += Constants.headerItemHorizontalOffset * CGFloat(selectedIndex + 1)
        // Semantically, this is the same as `UICollectionViewFlowLayout.minimumInteritemSpacing` from UIKit
        offset += Constants.headerInteritemSpacing * CGFloat(selectedIndex)
        return offset
    }

    private var animationsFactory: CardsInfoPagerAnimationFactory {
        let pageSwitchAnimationDuration = pageSwitchAnimationDurationConfigStorage[configStorageKey]
            ?? Constants.pageSwitchAnimationDuration

        return CardsInfoPagerAnimationFactory(
            hasValidIndexToSelect: hasValidIndexToSelect,
            currentPageSwitchProgress: pageSwitchProgress,
            minRemainingPageSwitchProgress: Constants.minRemainingPageSwitchProgress,
            pageSwitchAnimationDuration: pageSwitchAnimationDuration
        )
    }

    private var contentAnimationModifier: some AnimatableModifier {
        return CardsInfoPagerContentAnimationModifier(
            progress: pageSwitchProgress,
            verticalOffset: contentViewVerticalOffset,
            hasValidIndexToSelect: hasValidIndexToSelect
        )
    }

    // MARK: - Vertical auto scrolling (collapsible/expandable header)

    @StateObject private var scrollDetector = ScrollDetector()
    @StateObject private var scrollState = CardsInfoPagerScrollState()

    private let expandedHeaderScrollTargetIdentifier = UUID()
    private let collapsedHeaderScrollTargetIdentifier = UUID()
    private let scrollViewFrameCoordinateSpaceName = UUID()

    // TODO: Will be updated in IOS-5884
    /// Different headers for different pages are expected to have the same height (otherwise visual glitches may occur).
    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var headerHeight: CGFloat = .zero
    @State private var scrollViewBottomContentInset: CGFloat = .zero

    // MARK: - Configuration

    private let configStorageKey: AnyHashable
    private var contentViewVerticalOffset: CGFloat = Constants.contentViewVerticalOffset
    private var pageSwitchThreshold: CGFloat = Constants.pageSwitchThreshold
    private var isHorizontalScrollDisabled = false
    private var onPageChangeCallbacks: [OnPageChange] = []

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                makeScrollView(with: proxy)
                    .onAppear {
                        // `DispatchQueue.main.async` used here to allow publishing changes during view updates
                        DispatchQueue.main.async {
                            // Applying initial view's state based on the initial value of `selectedIndex`
                            cumulativeHorizontalTranslation = -CGFloat(selectedIndex) * proxy.size.width
                        }
                        scrollDetector.startDetectingScroll()
                        scrollState.onViewAppear()
                    }
                    .onDisappear(perform: scrollDetector.stopDetectingScroll)
                    .onChange(of: scrollState.contentOffset) { offset in
                        // Vertical scrolling may delay or even cancel horizontal scroll animations,
                        // which in turn may lead to desynchronization between `selectedIndex` and
                        // `contentSelectedIndex` properties.
                        // Therefore, we sync them forcefully when vertical scrolling starts.
                        synchronizeContentSelectedIndexIfNeeded()
                    }
                    .onChange(of: externalSelectedIndex) { newValue in
                        // Synchronizing external and private selected indices if needed
                        if newValue != selectedIndex {
                            switchPageProgrammatically(to: newValue, geometryProxy: proxy)
                        }
                    }
                    .onChange(of: data.count) { newValue in
                        // Handling edge cases when the very last page is selected and that page is being deleted
                        let clampedSelectedIndex = clamp(selectedIndex, min: selectedIndexLowerBound, max: newValue - 1)
                        if selectedIndex < clampedSelectedIndex || selectedIndex > clampedSelectedIndex {
                            switchPageProgrammatically(to: clampedSelectedIndex, geometryProxy: proxy)
                        }
                    }
                    .layoutPriority(1.0)

                makeBottomOverlay()
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .modifier(
            CardsInfoPagerContentSwitchingAnimationModifier(
                progress: pageSwitchProgress,
                finalPageSwitchProgress: finalPageSwitchProgress,
                initialSelectedIndex: previouslySelectedIndex,
                finalSelectedIndex: selectedIndex
            )
        )
        .onAnimationCompleted(for: cumulativeHorizontalTranslation) {
            // Last resort workaround for rare edge cases of desynchronization between `selectedIndex`
            // and `contentSelectedIndex` properties if multiple page switching animations in
            // different directions are launched simultaneously.
            // The desynchronization is hard to reproduce and the reasons for such behavior are unknown.
            // This workaround guarantees that at the end of all animations, the values in `selectedIndex`
            // and `contentSelectedIndex` properties will be in sync.
            synchronizeContentSelectedIndexIfNeeded()
        }
        .onPreferenceChange(CardsInfoPagerContentSwitchingAnimationModifier.PreferenceKey.self) { newValue in
            scheduleContentSelectedIndexUpdateIfNeeded(toNewValue: newValue)
        }
        .onChange(of: selectedIndex) { newValue in
            // Synchronizing private and external selected indices
            externalSelectedIndex = newValue
        }
        .onChange(of: swipeDiscoveryAnimationTrigger.trigger) { _ in
            playSwipeDiscoveryAnimation()
        }
    }

    // MARK: - Initialization/Deinitialization

    init(
        data: Data,
        id idProvider: KeyPath<(Data.Index, Data.Element), ID>,
        selectedIndex: Binding<Int>,
        discoveryAnimationTrigger: CardsInfoPagerSwipeDiscoveryAnimationTrigger,
        configStorageKey: AnyHashable,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        @ViewBuilder bottomOverlayFactory: @escaping BottomOverlayFactory,
        onPullToRefresh: OnPullToRefresh?
    ) {
        self.data = data
        self.idProvider = idProvider
        _selectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        _previouslySelectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        _contentSelectedIndex = .init(initialValue: selectedIndex.wrappedValue)
        _externalSelectedIndex = selectedIndex
        swipeDiscoveryAnimationTrigger = discoveryAnimationTrigger
        self.configStorageKey = configStorageKey
        self.headerFactory = headerFactory
        self.contentFactory = contentFactory
        self.bottomOverlayFactory = bottomOverlayFactory
        self.onPullToRefresh = onPullToRefresh
    }

    // MARK: - View factories

    @ViewBuilder
    private func makeHeader(with proxy: GeometryProxy) -> some View {
        // TODO: Andrey Fedorov - Migrate to LazyHStack (IOS-3771)
        HStack(spacing: Constants.headerInteritemSpacing) {
            ForEach(data.indexed(), id: idProvider) { index, element in
                headerFactory(element)
                    .frame(width: max(proxy.size.width - Constants.headerItemHorizontalOffset * 2.0, 0.0))
            }
        }
        .readGeometry(\.size.height, bindTo: $headerHeight)
        // This offset translates the page based on swipe
        .offset(x: currentHorizontalTranslation)
        // This offset determines which page is shown
        .offset(x: cumulativeHorizontalTranslation)
        // This offset is responsible for the next/previous cell peek
        .offset(x: headerItemPeekHorizontalOffset)
        .modifier(makeSwipeDiscoveryAnimationModifier(with: proxy))
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
            .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
            .readGeometry(\.size, bindTo: scrollState.viewportSizeSubject.asWriteOnlyBinding(.zero))
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

                if let element = data[safe: clampedContentSelectedIndex] {
                    contentFactory(element)
                        .modifier(contentAnimationModifier)
                }
            }
            .readGeometry(\.size, bindTo: scrollState.contentSizeSubject.asWriteOnlyBinding(.zero))
            .readContentOffset(
                inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                bindTo: scrollState.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )

            CardsInfoPagerFlexibleFooterView(
                contentSize: scrollState.contentSize,
                viewportSize: scrollState.viewportSize,
                headerTopInset: Constants.headerVerticalPadding,
                headerHeight: headerHeight + Constants.headerAdditionalSpacingHeight,
                bottomContentInset: scrollViewBottomContentInset
            )
        }
    }

    @ViewBuilder
    private func makeBottomOverlay() -> some View {
        if let element = data[safe: clampedContentSelectedIndex] {
            bottomOverlayFactory(
                element,
                CardsInfoPagerBottomOverlayFactoryParams(
                    isDraggingHorizontally: isDraggingHorizontally,
                    didScrollToBottom: scrollState.didScrollToBottom,
                    scrollOffset: scrollState.contentOffsetExceedingContentSize,
                    viewportSize: scrollState.viewportSize,
                    contentSize: scrollState.contentSize,
                    scrollViewBottomContentInset: scrollViewBottomContentInset
                )
            )
            .animation(.linear(duration: 0.1), value: scrollState.didScrollToBottom)
            .modifier(contentAnimationModifier)
            .readGeometry(\.size.height) { newValue in
                scrollViewBottomContentInset = newValue
                scrollState.bottomContentInsetSubject.send(newValue - Constants.scrollStateBottomContentInsetDiff)
            }
        }
    }

    private func makeSwipeDiscoveryAnimationModifier(with geometryProxy: GeometryProxy) -> some AnimatableModifier {
        // When there is more than one page and the last page is selected, it's animated in a 'reverse' manner
        // to show the previous page. Otherwise, pages are animated in a 'forward' manner to show the next page
        let offsetSign = (data.count > 1 && clampedContentSelectedIndex == selectedIndexUpperBound) ? 1.0 : -1.0
        let offset = geometryProxy.size.width * Constants.swipeDiscoveryOffsetToScreenWidthRatio

        return CardsInfoPagerSwipeDiscoveryAnimationModifier(
            progress: isSwipeDiscoveryAnimationActive ? 1.0 : 0.0,
            count: 1,
            offset: offset * offsetSign
        )
    }

    // MARK: - Gestures

    private func makeDragGesture(with proxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($currentHorizontalTranslation) { value, state, _ in
                state = valueWithRubberbandingIfNeeded(value.translation.width)
            }
            .updating($isDraggingHorizontally) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let totalWidth = proxy.size.width
                let adjustedWidth = totalWidth
                    - Constants.headerItemHorizontalOffset
                    - Constants.headerInteritemSpacing

                pageSwitchProgress = abs(valueWithRubberbandingIfNeeded(value.translation.width) / adjustedWidth)

                // The `content` part of the page must be updated exactly in the middle of the
                // current gesture/animation, therefore `nextPageThreshold` equals 0.5 here
                contentSelectedIndex = nextIndexToSelectClamped(
                    translation: value.translation.width,
                    totalWidth: totalWidth,
                    nextPageThreshold: 0.5
                )

                // The presence/absence of the next index to select must be determined as soon as possible
                // when drag gesture starts, therefore `nextPageThreshold` is a relatively small value here
                let nextIndexToSelect = nextIndexToSelectFiltered(
                    translation: value.translation.width,
                    totalWidth: totalWidth,
                    nextPageThreshold: 1.0 / 100000.0 // 0.001%
                )
                hasValidIndexToSelect = nextIndexToSelect != nil && nextIndexToSelect != selectedIndex
            }
            .onEnded { value in
                switchPage(method: .byGesture(value), geometryProxy: proxy)
            }
    }

    // MARK: - Horizontal scrolling support

    private func playSwipeDiscoveryAnimation() {
        isSwipeDiscoveryAnimationActive = false
        withAnimation(animationsFactory.makeSwipeDicoveryAnimation()) {
            isSwipeDiscoveryAnimationActive = true
        }
    }

    /// Additional horizontal translation which takes into account horizontal offsets for next/previous cell peeking.
    private func additionalHorizontalTranslation(
        oldSelectedIndex: Int,
        newSelectedIndex: Int
    ) -> CGFloat {
        let multiplier: CGFloat
        if oldSelectedIndex < newSelectedIndex {
            // Successful navigation to the next page (forward)
            multiplier = -1.0
        } else if oldSelectedIndex > newSelectedIndex {
            // Successful navigation to the previous page (reverse)
            multiplier = 1.0
        } else {
            // Page switch threshold hasn't been exceeded, no page switching has been made
            multiplier = 0.0
        }

        return (Constants.headerItemHorizontalOffset + Constants.headerInteritemSpacing) * multiplier
    }

    private func valueWithRubberbandingIfNeeded<T>(_ value: T) -> T where T: BinaryFloatingPoint {
        return hasValidIndexToSelect ? value : value.withRubberbanding()
    }

    private func switchPage(method: PageSwitchMethod, geometryProxy proxy: GeometryProxy) {
        let totalWidth = proxy.size.width
        let newSelectedIndex = newSelectedIndex(from: method, totalWidth: totalWidth)
        let pageHasBeenSwitched = newSelectedIndex != selectedIndex
        let gestureProperties = gestureProperties(from: method)

        cumulativeHorizontalTranslation += valueWithRubberbandingIfNeeded(gestureProperties.translation.width)
        cumulativeHorizontalTranslation += additionalHorizontalTranslation(
            oldSelectedIndex: selectedIndex,
            newSelectedIndex: newSelectedIndex
        )

        if pageSwitchThreshold > 0.5, !pageHasBeenSwitched {
            // Fixes edge cases for page switch thresholds > 0.5 when page switch threshold
            // hasn't been exceeded: reverse animation should restore `contentSelectedIndex`
            // back to `selectedIndex` value exactly in the middle of the animation.
            // In order to achieve that we have to assign `previouslySelectedIndex` to a
            // different value, or SwiftUI's `onChange(of:perform:)` callback won't be triggered.
            previouslySelectedIndex = contentSelectedIndex
        } else {
            previouslySelectedIndex = selectedIndex
        }

        selectedIndex = newSelectedIndex
        initialPageSwitchProgress = pageSwitchProgress
        finalPageSwitchProgress = pageHasBeenSwitched ? 1.0 : 0.0

        let animation = animationsFactory.makeHorizontalScrollAnimation(
            totalWidth: totalWidth,
            dragGestureVelocity: gestureProperties.velocity,
            pageHasBeenSwitched: pageHasBeenSwitched
        )
        withAnimation(animation) {
            cumulativeHorizontalTranslation = -CGFloat(newSelectedIndex) * totalWidth
            pageSwitchProgress = finalPageSwitchProgress
        }

        if pageHasBeenSwitched {
            notifyAboutSuccessfulPageChange(method: method)
        }
    }

    private func newSelectedIndex(from method: PageSwitchMethod, totalWidth: CGFloat) -> Int {
        switch method {
        case .byGesture(let gestureValue):
            return nextIndexToSelectClamped(
                translation: gestureValue.predictedEndTranslation.width,
                totalWidth: totalWidth,
                nextPageThreshold: pageSwitchThreshold
            )
        case .programmatically(let selectedIndex):
            return selectedIndex
        }
    }

    private func gestureProperties(from method: PageSwitchMethod) -> (translation: CGSize, velocity: CGSize) {
        switch method {
        case .byGesture(let gestureValue):
            return (gestureValue.translation, gestureValue.velocity)
        case .programmatically:
            return (.zero, .zero)
        }
    }

    /// Convenience helper which resets view's state before performing page switch programmatically.
    private func switchPageProgrammatically(to selectedIndex: Int, geometryProxy proxy: GeometryProxy) {
        resetViewStateBeforeSwitchingPageProgrammatically()
        switchPage(method: .programmatically(selectedIndex: selectedIndex), geometryProxy: proxy)
    }

    private func resetViewStateBeforeSwitchingPageProgrammatically() {
        withTransaction(.withoutAnimations()) {
            pageSwitchProgress = 0.0
            hasValidIndexToSelect = true
        }
    }

    private func notifyAboutSuccessfulPageChange(method: PageSwitchMethod) {
        onPageChangeCallbacks.forEach { $0(method.asPageChangeReason) }
    }

    // MARK: - Vertical auto scrolling support (collapsible/expandable header)

    private func performVerticalScrollIfNeeded(with scrollViewProxy: ScrollViewProxy) {
        let yOffset = scrollState.rawContentOffset.y - Constants.headerVerticalPadding

        guard 0.0 <= yOffset, yOffset < headerHeight else { return }

        let headerAutoScrollRatio: CGFloat
        if scrollState.proposedHeaderState == .collapsed {
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

    // MARK: - Selected index management

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
        return clamp(nextIndex, min: selectedIndexLowerBound, max: selectedIndexUpperBound)
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
        return (selectedIndexLowerBound ... selectedIndexUpperBound) ~= nextIndex ? nextIndex : nil
    }

    private func nextIndexToSelect(
        translation: CGFloat,
        totalWidth: CGFloat,
        nextPageThreshold: CGFloat
    ) -> Int {
        let adjustedWidth = totalWidth
            - Constants.headerItemHorizontalOffset
            - Constants.headerInteritemSpacing
        let gestureProgress = translation / (adjustedWidth * nextPageThreshold * 2.0)
        let indexDiff = Int(gestureProgress.rounded())
        // The difference is clamped because we don't want to switch
        // by more than one page at a time in case of overscroll
        return selectedIndex - clamp(indexDiff, min: -1, max: 1)
    }

    /// Multiple simultaneous page switching animations may finish roughly at the same time,
    /// therefore we have to debounce multiple updates of the `contentSelectedIndex` property.
    private func scheduleContentSelectedIndexUpdateIfNeeded(toNewValue newValue: Int) {
        // `contentSelectedIndex` is being updated in `onChanged(_:)` callback
        // during an active horizontal drag gesture, nothing to do here
        guard !isDraggingHorizontally else { return }

        scheduledContentSelectedIndexUpdate?.cancel()

        let scheduledUpdate = DispatchWorkItem {
            contentSelectedIndex = newValue
            scheduledContentSelectedIndexUpdate = nil
        }
        scheduledContentSelectedIndexUpdate = scheduledUpdate
        DispatchQueue.main.async(execute: scheduledUpdate)
    }

    private func synchronizeContentSelectedIndexIfNeeded() {
        if contentSelectedIndex != selectedIndex {
            contentSelectedIndex = selectedIndex
        }
    }
}

// MARK: - Setupable protocol conformance

extension CardsInfoPagerView: Setupable {
    /// Maximum vertical offset for the `content` part of the page during
    /// gesture-driven or animation-driven page switch
    func contentViewVerticalOffset(_ offset: CGFloat) -> Self {
        map { $0.contentViewVerticalOffset = offset }
    }

    func pageSwitchThreshold(_ threshold: CGFloat) -> Self {
        map { $0.pageSwitchThreshold = threshold }
    }

    /// Pass `nil` to use the default value.
    func pageSwitchAnimationDuration(_ value: CGFloat?) -> Self {
        map { pageSwitchAnimationDurationConfigStorage[$0.configStorageKey] = value ?? Constants.pageSwitchAnimationDuration }
    }

    func horizontalScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isHorizontalScrollDisabled = disabled }
    }

    func onPageChange(_ onPageChange: @escaping OnPageChange) -> Self {
        map { $0.onPageChangeCallbacks.append(onPageChange) }
    }
}

// MARK: - Auxiliary types

private extension CardsInfoPagerView {
    enum ProposedHeaderState {
        case collapsed
        case expanded
    }

    enum PageSwitchMethod {
        case byGesture(DragGesture.Value)
        case programmatically(selectedIndex: Int)

        var asPageChangeReason: CardsInfoPageChangeReason {
            switch self {
            case .byGesture:
                return .byGesture
            case .programmatically:
                return .programmatically
            }
        }
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
        static var pageSwitchAnimationDuration: TimeInterval { 0.7 }
        static var minRemainingPageSwitchProgress: CGFloat { 1.0 / 3.0 }
        static var scrollStateBottomContentInsetDiff: CGFloat { 14.0 }
        static var swipeDiscoveryOffsetToScreenWidthRatio: CGFloat { 0.175 } // Based on mockups
    }
}

// MARK: - A global storage for `pageSwitchAnimationDuration` config property

/// DO NOT replace this global storage with `let`/`var`/`@State`/`@StateObject` placed in the `CardsInfoPagerView` itself!
/// There is something seriously broken in SwiftUI's view state management - all approaches above will result in
/// old/stale values for the duration of the page switching animation in `switchPage(method:geometryProxy:)` method.
///
/// I have absolutely no clue why this is the case, but it is.
private var pageSwitchAnimationDurationConfigStorage: [AnyHashable: TimeInterval] = [:]

// MARK: - Previews

struct CardsInfoPagerView_Previews: PreviewProvider {
    private struct CardsInfoPagerPreview: View {
        var previewConfigs: [CardInfoPagePreviewConfig] {
            return [
                CardInfoPagePreviewConfig(initiallySelectedIndex: 0, hasPullToRefresh: true),
                CardInfoPagePreviewConfig(initiallySelectedIndex: 2, hasPullToRefresh: false),
            ]
        }

        var body: some View {
            ForEach(previewConfigs) { previewConfig in
                CardInfoPagePreviewContainerView(previewConfig: previewConfig)
            }
        }
    }

    static var previews: some View {
        CardsInfoPagerPreview()
    }
}
