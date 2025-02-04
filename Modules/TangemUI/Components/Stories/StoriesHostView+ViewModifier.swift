//
//  StoriesHostView+ViewModifier.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

private struct StoriesHostViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    let storiesPages: [[AnyView]]

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    if isPresented {
                        Color.black
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }

                    if isPresented {
                        StoriesHostView(isPresented: $isPresented, storiesPages: storiesPages)
                    }
                }
                .animation(.easeOut(duration: 0.4), value: isPresented)
            }
    }
}

// MARK: - SwiftUI.View modifier methods

public extension View {
    func storiesHost(isPresented: Binding<Bool>, storiesPages: [[AnyView]]) -> some View {
        modifier(StoriesHostViewModifier(isPresented: isPresented, storiesPages: storiesPages))
    }

    func storiesHost(singleStoryPages: [AnyView], isPresented: Binding<Bool>) -> some View {
        modifier(StoriesHostViewModifier(isPresented: isPresented, storiesPages: [singleStoryPages]))
    }

    func storiesHost<each PageView: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder singleStoryPagesViewBuilder: () -> TupleView <(repeat each PageView)>
    ) -> some View {
        var erasedViews = [AnyView]()
        for pageView in repeat each singleStoryPagesViewBuilder().value {
            erasedViews.append(AnyView(pageView))
        }

        return modifier(StoriesHostViewModifier(isPresented: isPresented, storiesPages: [erasedViews]))
    }
}
