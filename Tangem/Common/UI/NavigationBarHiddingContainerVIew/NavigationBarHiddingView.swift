//
//  NavigationBarHiddingView.swift
//  Tangem
//
//  Created by Andrew Son on 08.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct NavigationBarHiddingView<Content: View>: View {
    var shouldWrapInNavigationView: Bool
    var content: Content

    var body: some View {
        if #available(iOS 16.0, *) {
            wrappedContent
        } else {
            UIAppearanceBoundaryContainerView(boundaryMarker: NavigationBarHiddingViewUIAppearanceBoundaryMarker.self) {
                wrappedContent
            }
        }
    }

    @ViewBuilder
    private var wrappedContent: some View {
        if shouldWrapInNavigationView {
            NavigationView {
                contentWithModifiers
            }
        } else {
            contentWithModifiers
        }
    }

    @ViewBuilder
    private var contentWithModifiers: some View {
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
                .onAppear {
                    NavigationBarHiddingViewUIAppearanceBoundaryMarker.setupUIAppearanceIfNeeded()
                }
        }
    }

    init(shouldWrapInNavigationView: Bool, @ViewBuilder contentBuilder: () -> Content) {
        self.shouldWrapInNavigationView = shouldWrapInNavigationView
        content = contentBuilder()
    }
}

private class NavigationBarHiddingViewUIAppearanceBoundaryMarker: UIViewController {
    static var didSetupUIAppearance = false

    @available(iOS, obsoleted: 16.0, message: "Use native 'toolbarBackground(_:for:)' instead")
    static func setupUIAppearanceIfNeeded() {
        if #unavailable(iOS 16.0), !didSetupUIAppearance {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()

            let uiAppearance = UINavigationBar.appearance(
                whenContainedInInstancesOf: [NavigationBarHiddingViewUIAppearanceBoundaryMarker.self]
            )
            uiAppearance.compactAppearance = navBarAppearance
            uiAppearance.standardAppearance = navBarAppearance
            uiAppearance.scrollEdgeAppearance = navBarAppearance
            uiAppearance.compactScrollEdgeAppearance = navBarAppearance

            didSetupUIAppearance = true
        }
    }
}
