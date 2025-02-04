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
    let storiesPagesBuilder: (StoriesHostProxy) -> [[any View]]

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
                        StoriesHostView(isPresented: $isPresented, storiesPagesBuilder: storiesPagesBuilder)
                    }
                }
                .animation(.easeOut(duration: 0.4), value: isPresented)
            }
    }
}

// MARK: - SwiftUI.View modifier methods

public extension View {
    func storiesHost(isPresented: Binding<Bool>, storiesPagesBuilder: @escaping (StoriesHostProxy) -> [[any View]]) -> some View {
        modifier(StoriesHostViewModifier(isPresented: isPresented, storiesPagesBuilder: storiesPagesBuilder))
    }

    func storiesHost(isPresented: Binding<Bool>, singleStoryPagesBuilder: @escaping (StoriesHostProxy) -> [any View]) -> some View {
        let storiesPagesBuilder: (StoriesHostProxy) -> [[any View]] = { proxy in
            [singleStoryPagesBuilder(proxy)]
        }

        return storiesHost(isPresented: isPresented, storiesPagesBuilder: storiesPagesBuilder)
    }
}
