//
//  StoriesHostView+ViewModifier.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoriesHostViewModifier: ViewModifier {
    let storyPages: [[AnyView]]
    @Binding var isPresented: Bool

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
                        StoriesHostView(isPresented: $isPresented, storiesPages: storyPages)
                    }
                }
                .animation(.easeOut(duration: 0.4), value: isPresented)
            }
    }
}

extension View {
    public func storiesHost(storyPages: [[AnyView]], isPresented: Binding<Bool>) -> some View {
        modifier(StoriesHostViewModifier(storyPages: storyPages, isPresented: isPresented))
    }
}
