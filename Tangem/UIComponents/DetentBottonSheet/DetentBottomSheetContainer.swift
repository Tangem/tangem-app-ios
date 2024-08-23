//
//  DetentBottomSheetContainer.swift
//  Tangem
//
//  Created by skibinalexander on 05.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct DetentBottomSheetContainer<ContentView: View>: View {
    private let content: () -> ContentView

    // MARK: - Internal

    init(content: @escaping () -> ContentView) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            GrabberViewFactory()
                .makeSwiftUIView()

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Settings

extension DetentBottomSheetContainer {
    struct Settings {
        let background: Color
        let cornerRadius: CGFloat

        init(background: Color = .primary, cornerRadius: CGFloat = 24) {
            self.background = background
            self.cornerRadius = cornerRadius
        }
    }
}
