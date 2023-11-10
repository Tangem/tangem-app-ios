//
//  IOS15AndBelowScrollDisabledModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 03.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS, obsoleted: 16.0, message: "Delete when the minimum deployment target reaches 16.0")
struct IOS15AndBelowScrollDisabledModifier: ViewModifier {
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                ScrollDisablerView(isDisabled: isDisabled)
                    .frame(size: .zero)
                    .allowsHitTesting(false)
                    .accessibility(hidden: true)
            )
    }
}

// MARK: - Private implementation

private struct ScrollDisablerView: UIViewRepresentable {
    let isDisabled: Bool

    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        var currentUIView: UIView? = uiView

        while let nextUIView = currentUIView {
            if let uiScrollView = nextUIView as? UIScrollView {
                uiScrollView.isScrollEnabled = !isDisabled
                break
            }

            currentUIView = nextUIView.superview
        }
    }
}
