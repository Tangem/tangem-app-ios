//
//  RefreshableScrollView.swift
//  Tangem
//
//  Created by Alexander Osokin on 26.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

typealias RefreshCompletionHandler = () -> Void
typealias OnRefresh = (_ completionHandler: @escaping RefreshCompletionHandler) -> Void

/// Author: The SwiftUI Lab.
/// Full article: https://swiftui-lab.com/scrollview-pull-to-refresh/.
struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    @State private var alpha: Double = 0
    @State private var refreshing: Bool = false

    var threshold: CGFloat = 100
    let onRefresh: OnRefresh
    let content: Content

    init(
        height: CGFloat = 100,
        onRefresh: @escaping OnRefresh,
        @ViewBuilder content: () -> Content
    ) {
        threshold = height
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            refreshableScrollView
        } else {
            scrollViewWithHacks
        }
    }

    @available(iOS 16.0, *)
    private var refreshableScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
        }
        .refreshable {
            await withCheckedContinuation { continuation in
                onRefresh {
                    continuation.resume()
                }
            }
        }
    }

    private var scrollViewWithHacks: some View {
        return VStack {
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    MovingView()

                    VStack {
                        content
                    }
                    .alignmentGuide(
                        .top,
                        computeValue: { _ in (refreshing && frozen) ? -threshold : 0.0 }
                    )

                    SymbolView(
                        height: threshold,
                        loading: refreshing,
                        frozen: frozen,
                        rotation: rotation,
                        alpha: alpha
                    )
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                refreshLogic(values: values)
            }
        }
    }

    private func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        // `DispatchQueue.main.async` used here to allow publishing changes during view update
        DispatchQueue.main.async {
            // Calculating scroll offset
            let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero

            scrollOffset = movingBounds.minY - fixedBounds.minY

            rotation = symbolRotation(scrollOffset)
            alpha = symbolAlpha(scrollOffset)

            // Crossing the threshold on the way down, we start the refresh process
            if !refreshing, scrollOffset > threshold, previousScrollOffset <= threshold {
                refreshing = true

                // The consumer of this view may and most likely will change view hierarchy in `onRefresh` closure,
                // which in turn will interfere with view hierarchy changes made by changing our `frozen`/`refreshing`
                // state variables.
                // To prevent it, we're notifying the consumer of this view about triggered pull-to-refresh with some delay.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onRefresh {
                        withAnimation {
                            refreshing = false
                        }
                    }
                }
            }
            if refreshing {
                // Crossing the threshold on the way up, we add a space at the top of the scrollview
                if previousScrollOffset > threshold, scrollOffset < previousScrollOffset {
                    frozen = true
                }
            } else {
                // Removing the space at the top of the scroll view
                frozen = false
            }

            // Updating last scroll offset
            previousScrollOffset = scrollOffset
        }
    }

    private func symbolAnimationProgress(_ scrollOffset: CGFloat) -> Double {
        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        let h = Double(threshold)
        let d = Double(scrollOffset)
        let v = max(min(d - (h * 0.6), h * 0.4), 0)
        return v / (h * 0.4)
    }

    private func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        return .degrees(180 * symbolAnimationProgress(scrollOffset))
    }

    private func symbolAlpha(_ scrollOffset: Double) -> Double {
        return symbolAnimationProgress(scrollOffset)
    }

    private struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var frozen: Bool
        var rotation: Angle
        var alpha: Double

        var body: some View {
            Group {
                if loading { // If loading, show the activity control
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }.frame(height: height).fixedSize()
                        .offset(y: -height + (loading && frozen ? height : 0.0))
                } else {
                    Image(systemName: "arrow.down") // If not loading, show the arrow
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                        .padding(height * 0.375)
                        .rotationEffect(rotation)
                        .opacity(alpha)
                        .offset(y: -height + (loading && frozen ? +height : 0.0))
                }
            }
        }
    }

    private struct MovingView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: RefreshableKeyTypes.PrefKey.self,
                        value: [
                            RefreshableKeyTypes.PrefData(
                                vType: .movingView,
                                bounds: proxy.frame(in: .global)
                            ),
                        ]
                    )
            }.frame(height: 0)
        }
    }

    private struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: RefreshableKeyTypes.PrefKey.self,
                        value: [
                            RefreshableKeyTypes.PrefData(
                                vType: .fixedView,
                                bounds: proxy.frame(in: .global)
                            ),
                        ]
                    )
            }
        }
    }
}

// MARK: - Auxiliary types

private enum RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }

    fileprivate struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }

    fileprivate struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}

// MARK: - Previews

struct RefreshableScrollViewView_Previews: PreviewProvider {
    struct _ScrollView: View {
        @State private var text = "123456"

        var body: some View {
            RefreshableScrollView(onRefresh: { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completion()
                }
            }) {
                VStack {
                    Text("update state").onTapGesture {
                        text = "\(Date())"
                    }

                    Text("Row 1")
                    Text("Row 2")
                    Text("Row 3")
                }
            }
        }
    }

    static var previews: some View {
        _ScrollView()
            .previewDevice("iPhone 11 Pro Max")
    }
}
