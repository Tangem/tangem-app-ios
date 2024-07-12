//
//  RootViewControllerFactory.swift
//  Tangem
//
//  Created by m3g0byt3 on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct RootViewControllerFactory {
    func makeRootViewController(for rootView: some View) -> UIViewController {
        let contentViewController = UIHostingController(rootView: rootView)

        guard FeatureProvider.isAvailable(.markets) else {
            return contentViewController
        }

        let overlayViewController = UIHostingController(rootView: makeOverlayView())

        // TODO: Andrey Fedorov - Adjust all numeric values here for different devices and safe area
        return OverlayContentContainerViewController(
            contentViewController: contentViewController,
            overlayViewController: overlayViewController,
            overlayCollapsedHeight: 92.0, // https://www.figma.com/design/91bpyCrISuWSvUzTLmcYRc/iOS-%E2%80%93-Draft?node-id=21140-91435&t=Z1kPdSQJ0JLoYgW0-4
            overlayExpandedVerticalOffset: 54.0 // https://www.figma.com/design/91bpyCrISuWSvUzTLmcYRc/iOS-%E2%80%93-Draft?node-id=22985-125042&t=Z1kPdSQJ0JLoYgW0-4
        )
    }

    private func makeOverlayView() -> some View {
        return OverlayContentView(
            color: .green,
            hasScrollView: true
        )
    }
}

@available(*, deprecated, message: "Test only, remove")
struct OverlayContentView: View {
    let color: Color
    let hasScrollView: Bool

    @State private var pageTitleToShow: String? = nil

    var body: some View {
        NavigationView {
            color
                .overlay {
                    if hasScrollView {
                        List(0 ..< 100) { index in
                            Button("Row #\(index)") {
                                pageTitleToShow = "Page #\(index)"
                            }
                        }
                        .listStyle(.plain)
                    } else {
                        Button("Show second page") {
                            pageTitleToShow = "Second page"
                        }
                    }
                }
                .navigationTitle("First page")
                .navigationBarTitleDisplayMode(.inline)
                .navigationLinks(links)
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $pageTitleToShow) { pageTitleToShow in
                color
                    .overlay {
                        VStack {
                            Text(pageTitleToShow)
                        }
                    }
                    .navigationTitle(pageTitleToShow)
                    .navigationBarTitleDisplayMode(.inline)
            }
    }
}
