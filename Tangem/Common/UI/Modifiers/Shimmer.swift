//
//  Shimmer.swift
//  TangemApp
//
//  Created by Sergey Balashov on 09.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct Shimmer: ViewModifier {
    @State var isInitialState: Bool = true

    public func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    gradient: .init(colors: [.black, .black.opacity(0.4), .black]),
                    startPoint: isInitialState ? .init(x: -0.5, y: -0.5) : .init(x: 1, y: 1),
                    endPoint: isInitialState ? .init(x: 0, y: 0) : .init(x: 1.5, y: 1.5)
                )
            }
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isInitialState)
            .onAppear {
                isInitialState = false
            }
    }
}
