//
//  BottomScrollableSheet.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomScrollableSheet<Header: View, Content: View, Overlay: View>: View {
    @ViewBuilder private let header: () -> Header
    @ViewBuilder private let content: () -> Content
    @ViewBuilder private let overlay: () -> Overlay

    @Environment(\.bottomScrollableSheetStateObserver) private var bottomScrollableSheetStateObserver

    @ObservedObject private var stateObject: BottomScrollableSheetStateObject

    @Environment(\.statusBarStyleConfigurator) private var statusBarStyleConfigurator

    @State private var overlayHeight: CGFloat = .zero

    @State private var isHidden = true
    private var isHiddenWhenCollapsed = false

    private var prefersGrabberVisible = true

    /// - Note: The drag gesture is enabled only when the sheet in is an expanded state (`BottomScrollableSheetState.top`).
    /// Otherwise, a drag gesture from the `headerGestureOverlayView` view is used.
    private var headerDragGestureMask: GestureMask { stateObject.state.isBottom ? .subviews : .all }

    private var scrollViewBottomContentInset: CGFloat { max(overlayHeight, UIApplication.safeAreaInsets.bottom, 6.0) }

    private let coordinateSpaceName = UUID()

    init(
        stateObject: BottomScrollableSheetStateObject,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.stateObject = stateObject
        self.header = header
        self.content = content
        self.overlay = overlay
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundView

                sheet(proxy: proxy)
                    .infinityFrame(axis: .vertical, alignment: .bottom)
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear(perform: stateObject.onAppear)
            .onDisappear(perform: restoreStatusBarColorScheme)
            .onChange(of: stateObject.state) { newValue in
                bottomScrollableSheetStateObserver?(newValue)
            }
            .onChange(of: stateObject.preferredStatusBarColorScheme) { newValue in
                statusBarStyleConfigurator.setSelectedStatusBarColorScheme(newValue, animated: true)
            }
            .readGeometry(bindTo: stateObject.geometryInfoSubject.asWriteOnlyBinding(.zero))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var headerDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged(stateObject.headerDragGesture(onChanged:))
            .onEnded(stateObject.headerDragGesture(onEnded:))
    }

    private var headerTapGesture: some Gesture {
        TapGesture()
            .onEnded(stateObject.onHeaderTap)
    }

    @ViewBuilder private var headerView: some View {
        header()
            .gesture(headerDragGesture, including: headerDragGestureMask)
            .if(prefersGrabberVisible) { $0.bottomScrollableSheetGrabber() }
            .readGeometry(\.size.height, bindTo: $stateObject.headerHeight)
    }

    /// - Note: Invisible and receives touches only when the sheet is in a collapsed state (`BottomScrollableSheetState.bottom`).
    @ViewBuilder private var headerGestureOverlayView: some View {
        // The reduced hittest area is used here to prevent simultaneous recognition of the `headerDragGesture`
        // or `headerTapGesture` gestures and the system `app switcher` screen edge drag gesture.
        let overlayViewHeight = max(0.0, stateObject.headerHeight - UIApplication.safeAreaInsets.bottom)
        Color.clear
            .frame(height: overlayViewHeight, alignment: .top)
            .contentShape(Rectangle())
            .gesture(headerTapGesture)
            .simultaneousGesture(headerDragGesture)
            .allowsHitTesting(stateObject.state.isBottom)
    }

    @ViewBuilder private var backgroundView: some View {
        Color.black
            .opacity(Constants.backgroundViewOpacity * stateObject.progress)
            .ignoresSafeArea()
    }

    @ViewBuilder private var scrollView: some View {
        ScrollView(.vertical) {
            ZStack {
                DragGesturePassthroughView(
                    onChanged: stateObject.scrollViewContentDragGesture(onChanged:),
                    onEnded: stateObject.scrollViewContentDragGesture(onEnded:)
                )

                VStack(spacing: 0.0) {
                    content()
                        .readContentOffset(
                            inCoordinateSpace: .named(coordinateSpaceName),
                            throttleInterval: .standard,
                            bindTo: stateObject.contentOffsetSubject.asWriteOnlyBinding(.zero)
                        )

                    FixedSpacer(height: scrollViewBottomContentInset, length: scrollViewBottomContentInset)
                        .fixedSize()
                }
                .layoutPriority(1000.0) // This child defines the layout of the outer container, so a higher layout priority is used
            }
            .ios15AndBelowScrollDisabledCompat(stateObject.scrollViewIsDragging)
        }
        .ios16AndAboveScrollDisabledCompat(stateObject.scrollViewIsDragging)
        .overlay(
            overlay()
                .readGeometry(\.size.height, bindTo: $overlayHeight)
                .infinityFrame(alignment: .bottom)
        )
        .coordinateSpace(name: coordinateSpaceName)
    }

    @ViewBuilder
    private func sheet(proxy: GeometryProxy) -> some View {
        ZStack {
            Colors.Background.primary

            VStack(spacing: 0.0) {
                headerView

                scrollView
            }
            .layoutPriority(1000.0) // This child defines the layout of the outer container, so a higher layout priority is used
        }
        .frame(height: proxy.size.height - stateObject.topInset)
        .bottomScrollableSheetCornerRadius()
        .bottomScrollableSheetShadow()
        .hidden(isHiddenWhenCollapsed ? isHidden : false)
        .onAnimationStarted(for: stateObject.progress) {
            if isHidden {
                isHidden = false
            }
        }
        .onAnimationCompleted(for: stateObject.progress) {
            if !isHidden, stateObject.progress < .ulpOfOne {
                isHidden = true
            }
        }
        .overlay(headerGestureOverlayView, alignment: .top) // Mustn't be hidden (by the 'isHidden' flag applied above)
        .offset(y: proxy.size.height - stateObject.visibleHeight - stateObject.topInset)
    }

    /// Restores default (system-driven) appearance of the status bar.
    private func restoreStatusBarColorScheme() {
        statusBarStyleConfigurator.setSelectedStatusBarColorScheme(nil, animated: true)
    }
}

// MARK: - Setupable protocol conformance

extension BottomScrollableSheet: Setupable {
    func prefersGrabberVisible(_ visible: Bool) -> Self {
        map { $0.prefersGrabberVisible = visible }
    }

    func isHiddenWhenCollapsed(_ isHidden: Bool) -> Self {
        map { $0.isHiddenWhenCollapsed = isHidden }
    }
}

// MARK: - Constants

private extension BottomScrollableSheet {
    enum Constants {
        static var backgroundViewOpacity: CGFloat { 0.5 }
    }
}

// MARK: - Convenience extensions

private extension View {
    func onAnimationStarted<Value>(
        for value: Value,
        completion: @escaping () -> Void
    ) -> some View where Value: VectorArithmetic, Value: Comparable, Value: ExpressibleByFloatLiteral {
        modifier(
            AnimationProgressObserverModifier(
                observedValue: value,
                targetValue: 0.0,
                valueComparator: >,
                action: completion
            )
        )
    }
}
