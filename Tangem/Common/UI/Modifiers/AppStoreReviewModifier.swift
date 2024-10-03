//
//  AppStoreReviewModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import StoreKit

// MARK: - Convenience extensions

extension View {
    @available(iOS, deprecated: 16.0, message: "Use native 'RequestReviewAction' instead")
    @ViewBuilder
    func requestAppStoreReviewCompat(_ shouldRequest: Binding<Bool>) -> some View {
        if #available(iOS 16.0, *) {
            modifier(AppStoreReviewModifier(shouldRequest: shouldRequest))
        } else {
            modifier(AppStoreReviewModifierCompat(shouldRequest: shouldRequest))
        }
    }
}

// MARK: - Private implementation

@available(iOS, introduced: 16.0, deprecated: 16.0, message: "Use native 'RequestReviewAction' instead")
private struct AppStoreReviewModifier: ViewModifier {
    @Binding var shouldRequest: Bool

    @Environment(\.requestReview) private var requestReview

    func body(content: Content) -> some View {
        content
            .onChange(of: shouldRequest) { newValue in
                guard newValue else { return }

                shouldRequest.toggle()
                requestReview()
            }
    }
}

@available(iOS, obsoleted: 16.0, message: "Use native 'RequestReviewAction' instead")
private struct AppStoreReviewModifierCompat: ViewModifier {
    @Binding var shouldRequest: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: shouldRequest) { newValue in
                guard newValue else { return }

                shouldRequest.toggle()
                requestReview()
            }
    }

    private func requestReview() {
        guard let windowScene = UIApplication.activeScene else { return }

        DispatchQueue.main.async {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
