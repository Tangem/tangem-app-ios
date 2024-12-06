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
    @StateObject private var refreshContainer: RefreshContainer

    let content: Content

    init(
        onRefresh: @escaping OnRefresh,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        _refreshContainer = StateObject(wrappedValue: RefreshContainer(onRefresh: onRefresh))
    }

    var body: some View {
        if #available(iOS 16, *) {
            ScrollView(.vertical, showsIndicators: false) {
                content
            }
            .refreshable { [weak refreshContainer] in
                await refreshContainer?.refreshAsync()
            }
        } else {
            RefreshableScrollViewCompat(onRefresh: refreshContainer.onRefresh, content: content)
        }
    }
}

@available(iOS, obsoleted: 16, message: "iOS 15 doesn't fully support refreshable for ScrollView. Can be removed after update min OS version to 16 (IOS-5885)")
private struct RefreshableScrollViewCompat<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    @State private var alpha: Double = 0
    @State private var refreshing: Bool = false

    private let coordinateSpaceName = UUID()

    var threshold: CGFloat = 100
    let onRefresh: OnRefresh
    let content: Content

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    SymbolView(
                        height: threshold,
                        loading: refreshing,
                        frozen: frozen,
                        rotation: rotation,
                        alpha: alpha
                    )

                    content
                }
                .offset(y: -threshold + ((refreshing && frozen) ? threshold : 0.0))
                .readContentOffset(inCoordinateSpace: .named(coordinateSpaceName)) { value in
                    refreshLogic(offset: value)
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
    }

    private struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var frozen: Bool
        var rotation: Angle
        var alpha: Double
        var body: some View {
            ZStack {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .opacity(loading ? 1.0 : 0.0)

                Image(systemName: "arrow.down") // If not loading, show the arrow
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: height * 0.25, height: height * 0.25)
                    .padding(height * 0.375)
                    .rotationEffect(rotation)
                    .opacity(loading ? 0 : alpha)
            }
            .frame(height: height)
        }
    }

    private func refreshLogic(offset: CGPoint) {
        scrollOffset = -offset.y

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

    private func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        return .degrees(180 * symbolAnimationProgress(scrollOffset))
    }

    private func symbolAlpha(_ scrollOffset: Double) -> Double {
        return symbolAnimationProgress(scrollOffset)
    }

    private func symbolAnimationProgress(_ scrollOffset: CGFloat) -> Double {
        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        let h = Double(threshold)
        let d = Double(scrollOffset)
        let v = max(min(d - (h * 0.6), h * 0.4), 0)
        return v / (h * 0.4)
    }
}

// MARK: - RefreshContainer

extension RefreshableScrollView {
    private final class RefreshContainer: ObservableObject {
        let onRefresh: OnRefresh

        init(onRefresh: @escaping OnRefresh) {
            self.onRefresh = onRefresh
        }

        @MainActor
        func refreshAsync() async {
            await withCheckedContinuation { continuation in
                onRefresh {
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Previews

struct RefreshableScrollViewView_Previews: PreviewProvider {
    struct _ScrollView: View {
        @State private var text = "0"
        @State private var updatesCounter = 0

        var body: some View {
            RefreshableScrollView(onRefresh: { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completion()
                }
            }) {
                VStack {
                    Text("Update counter: \(updatesCounter)")
                    Spacer(minLength: 300)
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
