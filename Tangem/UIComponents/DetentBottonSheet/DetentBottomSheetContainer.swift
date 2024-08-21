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

    private let indicatorSize = CGSize(width: 32, height: 4)

    init(content: @escaping () -> ContentView) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: indicatorSize)
                .padding(.vertical, 8)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Settings

extension DetentBottomSheetContainer {
    struct Settings {
        let cornerRadius: CGFloat

        init(cornerRadius: CGFloat = 24) {
            self.cornerRadius = cornerRadius
        }
    }
}
