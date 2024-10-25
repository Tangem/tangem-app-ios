//
//  BottomSheetContainer.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetContainer<ContentView: View>: View {
    @ObservedObject private var stateObject: StateObject
    private let settings: Settings
    private let content: () -> ContentView

    // MARK: - Internal

    @State private var isContentViewGestureActive = false
    @State private var isBottomSheetContainerGestureActive = false
    @State private var shouldCheckBottomSheetContainerGesture = true

    private var opacity: CGFloat {
        max(0, settings.backgroundOpacity * stateObject.dragPercentage)
    }

    private var gestureMask: GestureMask {
        // Exclusively enable our drag gesture and disable all gestures in the subview hierarchy
        if isBottomSheetContainerGestureActive {
            return .gesture
        }

        // Enable all gestures in the subview hierarchy but disable our drag gesture
        if isContentViewGestureActive {
            return .subviews
        }

        // Default behavior, all gestures are enabled
        return .all
    }

    private var transitionAnimation: Animation {
        .easeOut(duration: settings.animationDuration)
    }

    init(
        stateObject: StateObject,
        settings: Settings,
        content: @escaping () -> ContentView
    ) {
        self.stateObject = stateObject
        self.settings = settings
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(opacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(perform: backgroundDidTapped)
                .animation(.default.delay(settings.backgroundAnimationDelay), value: opacity)

            sheetView
                .transition(.move(edge: .bottom))
                // Fix for black outing the sheet after dismiss externally
                .zIndex(1)

            settings.backgroundColor
                // For hide bottom space when sheet is up
                .frame(height: abs(min(0, stateObject.offset)))
                // Added to hide the line between views
                .offset(y: -1)
        }
        .edgesIgnoringSafeArea(.all)
    }

    private var sheetView: some View {
        VStack(spacing: 0) {
            indicator

            content()
                .padding(.bottom, UIApplication.safeAreaInsets.bottom)
                .if(settings.contentScrollsHorizontally) { view in
                    view.modifier(ContentHorizontalScrollDetectionViewModifier())
                }
                .onPreferenceChange(ContentHorizontalScrollDetectionViewModifier.PreferenceKey.self) { newValue in
                    isContentViewGestureActive = newValue

                    // The content view gesture has ended, therefore there may be an opportunity for our drag gesture
                    // to start again. Resetting the state of our drag gesture to allow it to start
                    if !newValue {
                        resetGestureState()
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
        .cornerRadius(settings.cornerRadius, corners: [.topLeft, .topRight])
        .readGeometry(\.size.height, bindTo: $stateObject.contentHeight)
        .simultaneousGesture(dragGesture, including: gestureMask)
        .offset(y: stateObject.offset)
    }

    private var indicator: some View {
        ZStack {
            GrabberViewFactory()
                .makeSwiftUIView()
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                // One-time (the cycle ends with an `onEnded` closure call) check if we should start our drag gesture
                if shouldCheckBottomSheetContainerGesture {
                    shouldCheckBottomSheetContainerGesture = false

                    if value.isMovingInVerticalDirection, !isContentViewGestureActive {
                        isBottomSheetContainerGestureActive = true
                    }
                }

                guard isBottomSheetContainerGestureActive else {
                    return
                }

                if !stateObject.isDragging {
                    stateObject.isDragging = true
                }

                let locationChange = value.startLocation.y - value.location.y

                switch settings.hidingOption {
                case .distance where locationChange > 0:
                    // If user drags on up then reduce the dragging value
                    stateObject.offset = -locationChange.withRubberbanding()

                case .distance:
                    stateObject.offset = -locationChange

                case .nonHideable:
                    stateObject.offset = -locationChange.withRubberbanding()
                }
            }
            .onEnded { value in
                stateObject.isDragging = false

                resetGestureState()

                switch settings.hidingOption {
                case .distance(let distanceToHide) where value.translation.height > distanceToHide:
                    // If swipe was been enough to hide view
                    hideView {
                        stateObject.viewDidHidden()
                    }
                case .distance, .nonHideable:
                    // Otherwise set the view to default state
                    withAnimation(.default) {
                        stateObject.offset = 0
                    }
                }
            }
    }

    // MARK: - Methods

    func backgroundDidTapped() {
        guard case .distance = settings.hidingOption else {
            return
        }

        hideView {
            stateObject.viewDidHidden()
        }
    }

    func hideView(completion: @escaping () -> Void) {
        let animationBody = {
            stateObject.offset = UIScreen.main.bounds.height
        }

        if #available(iOS 17, *) {
            withAnimation(transitionAnimation, animationBody, completion: completion)
        } else {
            withAnimation(transitionAnimation, animationBody)

            let duration = settings.animationDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion()
            }
        }
    }

    func showView() {
        withAnimation(transitionAnimation) {
            stateObject.offset = 0
        }
    }

    private func resetGestureState() {
        shouldCheckBottomSheetContainerGesture = true
        isBottomSheetContainerGestureActive = false
    }
}

// MARK: - Settings

extension BottomSheetContainer {
    struct Settings {
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let backgroundOpacity: CGFloat
        let hidingOption: HidingOption
        let animationDuration: Double
        let backgroundAnimationDelay: TimeInterval
        /// Enable to prevent vertical/horizontal gesture conflicts when the bottom sheet content view
        /// contains a horizontal scroll. Disabled by default.
        let contentScrollsHorizontally: Bool

        enum HidingOption {
            case distance(CGFloat = UIScreen.main.bounds.height * 0.1)
            case nonHideable
        }

        init(
            cornerRadius: CGFloat = 24,
            backgroundColor: Color,
            backgroundOpacity: CGFloat = 0.4,
            hidingOption: HidingOption = .distance(),
            animationDuration: Double = 0.25,
            backgroundAnimationDelay: TimeInterval = 0.0,
            contentScrollsHorizontally: Bool = false
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.backgroundOpacity = backgroundOpacity
            self.hidingOption = hidingOption
            self.animationDuration = animationDuration
            self.backgroundAnimationDelay = backgroundAnimationDelay
            self.contentScrollsHorizontally = contentScrollsHorizontally
        }
    }
}

// MARK: - StateObject

extension BottomSheetContainer {
    class StateObject: ObservableObject {
        @Published var contentHeight: CGFloat = UIScreen.main.bounds.height / 2
        @Published var isDragging: Bool = false
        @Published var offset: CGFloat = UIScreen.main.bounds.height

        public var dragPercentage: CGFloat {
            let visibleHeight = contentHeight - offset
            let percentage = visibleHeight / contentHeight
            return max(0, percentage)
        }

        public var viewDidHidden: () -> Void = {}
    }
}

// MARK: - Content horizontal scrolling compatibility

private extension BottomSheetContainer {
    /// Detects horizontal scrolling in the content view, helps resolve conflicts between the bottom sheet
    /// vertical drag gesture and the horizontal drag gesture in the content view.
    /// Native SwiftUI approaches such as `Gesture.sequenced(before:)` and `Gesture.exclusively(before:)` can't be used
    /// here because bottom sheet is a content-agnostic UI component and knows nothing about its child view hierarchy.
    struct ContentHorizontalScrollDetectionViewModifier: ViewModifier {
        struct PreferenceKey: SwiftUI.PreferenceKey {
            static var defaultValue: Bool { false }

            static func reduce(value: inout Bool, nextValue: () -> Bool) {}
        }

        @GestureState
        private var isContentViewGestureActive = false

        /// A dummy drag gesture used to detect horizontal scrolling in the content view.
        private var dragGesture: some Gesture {
            DragGesture()
                .updating($isContentViewGestureActive) { value, state, _ in
                    if value.isMovingInHorizontalDirection {
                        state = true
                    }
                }
        }

        func body(content: Content) -> some View {
            content
                .simultaneousGesture(dragGesture)
                .preference(key: PreferenceKey.self, value: isContentViewGestureActive)
        }
    }
}

// MARK: - Previews

struct BottomSheetContainer_Previews: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = BottomSheetCoordinator()

        var body: some View {
            ZStack {
                Colors.Background.primary
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $coordinator.item, backgroundColor: Colors.Background.tertiary) {
                        BottomSheetView(viewModel: $0)
                    }
            }
        }
    }

    struct BottomSheetViewModel: Identifiable {
        var id: String { payload }

        let payload: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let close: () -> Void
    }

    struct BottomSheetView: View {
        let viewModel: BottomSheetViewModel

        var body: some View {
            VStack {
                GroupedSection(viewModel) { viewModel in
                    ForEach(0 ..< 3) { _ in
                        Text(viewModel.payload)
                            .padding(.vertical)

                        Divider()
                    }
                }

                VStack {
                    MainButton(title: Localization.commonCancel, style: .primary, action: viewModel.close)

                    MainButton(title: Localization.commonClose, style: .secondary, action: viewModel.close)
                }
            }
            .padding(.horizontal)
        }
    }

    class BottomSheetCoordinator: ObservableObject {
        @Published var item: BottomSheetViewModel?

        func toggleItem() {
            if item == nil {
                item = BottomSheetViewModel { [weak self] in
                    self?.item = nil
                }
            } else {
                item = nil
            }
        }
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
