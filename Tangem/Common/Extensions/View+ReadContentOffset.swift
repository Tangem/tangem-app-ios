//
//  View+ReadContentOffset.swift
//  Tangem
//
//  Created by Andrey Fedorov on 04/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /**
     1. Assign stable coordinate space to the scroll view itself.
     2. Use this modifier on container view (like `VStack` or `HStack`) used inside scroll view.
     ```
     struct SomeView: View {
        private let name = UUID()
        @State private var contentOffset: CGPoint = .zero

        func body(content: Content) -> some View {
            ScrollView {
                LazyVStack() {
                    // Some scrollable content
                }
                .readContentOffset(to: $contentOffset, inCoordinateSpace: .named(name)
            )
            .coordinateSpace(name: name)
        }
     }
     ```
     */
    func readContentOffset(
        to contentOffset: Binding<CGPoint>,
        inCoordinateSpace coordinateSpace: CoordinateSpace
    ) -> some View {
        modifier(
            ContentOffsetReaderViewModifier(
                contentOffset: contentOffset,
                coordinateSpace: coordinateSpace
            )
        )
    }
}

private struct ContentOffsetReaderViewModifier: ViewModifier {
    let contentOffset: Binding<CGPoint>
    let coordinateSpace: CoordinateSpace

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ContentOffsetReaderPreferenceKey.self,
                        value: proxy.frame(in: coordinateSpace).origin
                    )
                }
            )
            .onPreferenceChange(ContentOffsetReaderPreferenceKey.self) { value in
                contentOffset.wrappedValue = CGPoint(
                    x: -value.x,
                    y: -value.y
                )
            }
    }
}

private struct ContentOffsetReaderPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint { .zero }

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
