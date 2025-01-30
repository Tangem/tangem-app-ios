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
                pageViews[viewModel.visiblePageIndex]
            }
            .gesture(shortTapGesture(proxy))
            .highPriorityGesture(longTapGesture)
            .overlay(alignment: .top) {
                progressBar
            }
            .background {
                cubicTransitionTracker
            }
            .rotation3DEffect(
                CubicRotation.angle(proxy),
                axis: (x: 0, y: 1, z: 0),
                anchor: CubicRotation.anchor(proxy),
                perspective: CubicRotation.perspective
            )
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
            ForEach(0 ..< pageViews.count, id: \.self) { pageIndex in
                GeometryReader { proxy in
                    Capsule()
                        .fill(.white.opacity(0.5))
                        .overlay(alignment: .leading) {
                            let width = pageProgressWidth(for: pageIndex, proxy: proxy)
                            Capsule()
                                .fill(.white)
                                .frame(width: width)
                        }
                        .clipped()
                }
            }
        }
        .frame(height: 2)
        .padding(.top, 8)
        .padding(.horizontal, 8)
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
                    let tapLocation = drag?.location ?? .zero
                    let threshold = Constants.tapToBackThresholdPercentage * proxy.size.width

                    let viewEvent: StoryViewEvent = tapLocation.x < threshold
                        ? .tappedBackward
                        : .tappedForward

                    viewModel.handle(viewEvent: viewEvent)

                default:
                    break
                }
            }
    }

    private func pageProgressWidth(for index: Int, proxy: GeometryProxy) -> CGFloat {
        return proxy.size.width * viewModel.pageProgress(for: index)
    }
}

// MARK: - Nested private types

extension StoryView {
    private enum CubicRotation {
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
        static let tapToBackThresholdPercentage: CGFloat = 0.25
        static let longPressMinimumDuration: TimeInterval = 0.2
    }
}
