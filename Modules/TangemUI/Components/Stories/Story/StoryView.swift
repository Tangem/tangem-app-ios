//
//  StoryView.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    let pageViews: [StoryPageView]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                preiOS18Gestures(proxy)
                pageViews[viewModel.visiblePageIndex]
            }
            .modifier(if: Self.iOS18Available) { content in
                content
                    .gesture(longTapGesture)
                    .gesture(shortTapGesture(proxy))
            }
            .overlay(alignment: .top) {
                progressBar
            }
            .background {
                cubicTransitionTracker
            }
            .cubicRotationEffect(proxy)
        }
        .onAppear {
            viewModel.handle(viewEvent: .viewDidAppear)
        }
        .onDisappear {
            viewModel.handle(viewEvent: .viewDidDisappear)
        }
        .onPreferenceChange(CubicTransitionProgressKey.self) { newValue in
            let isDuringTransition = newValue != 0

            let viewEvent: StoryViewEvent = isDuringTransition
                ? .viewInteractionPaused
                : .viewInteractionResumed

            viewModel.handle(viewEvent: viewEvent)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(Array(pageViews.indices), id: \.self, content: pageProgressView)
        }
        .frame(height: 2)
        .padding(.top, 8)
        .padding(.horizontal, 8)
    }

    private func pageProgressView(_ pageIndex: Int) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(.white.opacity(0.5))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.white)
                        .frame(width: pageProgressWidth(for: pageIndex, proxy: proxy))
                }
                .clipped()
        }
    }

    private var cubicTransitionTracker: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: CubicTransitionProgressKey.self,
                    value: proxy.frame(in: .global).minX / proxy.size.width
                )
        }
    }

    private func pageProgressWidth(for index: Int, proxy: GeometryProxy) -> CGFloat {
        return proxy.size.width * viewModel.pageProgress(for: index)
    }

    private static var iOS18Available: Bool {
        if #available(iOS 18.0, *) {
            return true
        }

        return false
    }
}

// MARK: - Gestures

extension StoryView {
    private var longTapGesture: some Gesture {
        LongPressGesture(minimumDuration: Constants.longPressMinimumDuration)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { _ in
                viewModel.handle(viewEvent: .longTapPressed)
            }
            .onEnded { _ in
                viewModel.handle(viewEvent: .longTapEnded)
            }
    }

    private func shortTapGesture(_ proxy: GeometryProxy) -> some Gesture {
        TapGesture()
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                switch value {
                case .second(_, let drag):
                    handleShortTap(drag?.location ?? .zero, proxy: proxy)
                default:
                    break
                }
            }
    }

    @ViewBuilder
    private func preiOS18Gestures(_ proxy: GeometryProxy) -> some View {
        if !Self.iOS18Available {
            GestureRecognizerView(
                tapAction: { tapLocation in
                    handleShortTap(tapLocation, proxy: proxy)
                },
                longTapStartedAction: {
                    viewModel.handle(viewEvent: .longTapPressed)
                },
                longTapEndedAction: {
                    viewModel.handle(viewEvent: .longTapEnded)
                }
            )
        }
    }

    private func handleShortTap(_ tapLocation: CGPoint, proxy: GeometryProxy) {
        let threshold = Constants.tapToBackThresholdPercentage * proxy.size.width

        let viewEvent: StoryViewEvent = tapLocation.x < threshold
            ? .tappedBackward
            : .tappedForward

        viewModel.handle(viewEvent: viewEvent)
    }
}

// MARK: - Private nested types

extension StoryView {
    fileprivate enum CubicRotation {
        static let perspective: CGFloat = 2.5

        static func angle(_ proxy: GeometryProxy) -> Angle {
            let progress = proxy.frame(in: .global).minX / proxy.size.width
            let squareRotationAngle: Double = 45
            return Angle(degrees: squareRotationAngle * progress)
        }

        static func anchor(_ proxy: GeometryProxy) -> UnitPoint {
            proxy.frame(in: .global).minX > 0
                ? .leading
                : .trailing
        }
    }

    private struct CubicTransitionProgressKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value += nextValue()
        }
    }

    private enum Constants {
        /// 0.25
        static let tapToBackThresholdPercentage: CGFloat = 0.25
        /// 0.2
        static let longPressMinimumDuration: TimeInterval = 0.2
    }
}

// MARK: - View extensions

private extension View {
    func cubicRotationEffect(_ proxy: GeometryProxy) -> some View {
        // @alobankov, 0.0001 is a 'any small number close to zero'. Used to silence warning that may happen during transition backwards.
        rotation3DEffect(
            StoryView.CubicRotation.angle(proxy),
            axis: (x: 0.0001, y: 1, z: 0),
            anchor: StoryView.CubicRotation.anchor(proxy),
            perspective: StoryView.CubicRotation.perspective
        )
    }
}

extension StoryView {
    private struct GestureRecognizerView: UIViewRepresentable {
        let tapAction: (CGPoint) -> Void
        let longTapStartedAction: () -> Void
        let longTapEndedAction: () -> Void

        func makeUIView(context: Context) -> some UIView {
            let view = GestureRecognizerUIView(
                tapAction: tapAction,
                longTapStartedAction: longTapStartedAction,
                longTapEndedAction: longTapEndedAction
            )
            view.backgroundColor = .clear
            return view
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    private final class GestureRecognizerUIView: UIView {
        let tapAction: (CGPoint) -> Void
        let longTapStartedAction: () -> Void
        let longTapEndedAction: () -> Void

        init(
            tapAction: @escaping (CGPoint) -> Void,
            longTapStartedAction: @escaping () -> Void,
            longTapEndedAction: @escaping () -> Void
        ) {
            self.tapAction = tapAction
            self.longTapStartedAction = longTapStartedAction
            self.longTapEndedAction = longTapEndedAction

            super.init(frame: .zero)

            setupGestures()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupGestures() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Self.handleTapGesture))
            addGestureRecognizer(tapGesture)

            let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(Self.handleLongTapGesture))
            longTapGesture.minimumPressDuration = 0.2
            addGestureRecognizer(longTapGesture)
        }

        @objc
        private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            let tapLocation = gesture.location(in: gesture.view)
            tapAction(tapLocation)
        }

        @objc
        private func handleLongTapGesture(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                longTapStartedAction()

            case .ended, .cancelled:
                longTapEndedAction()

            default:
                break
            }
        }
    }
}
