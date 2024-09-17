//
//  UIAppearanceBoundaryContainerView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

/// Wrapper to limit propagation of changes made by using the `UIAppearance` API.
///
/// `BoundaryMarker` type must be unique within the boundaries of a particular namespace.
/// Some examples of namespaces are the app target itself, a SPM module, and a static/dynamic library.
///
/// Consider the following example:
/// ```
/// struct SomeView: View {
///     private static var didSetupUIAppearance = false
///
///     var body: some View {
///         UIAppearanceBoundaryContainerView(boundaryMarker: DummyMarkOnlyUIViewControllerSubclass.self) {
///             List(0..<10) { element in
///                 Text(String(describing: element))
///             }
///             .onAppear { Self.setupUIAppearanceIfNeeded() }
///         }
///     }
///
///     private static func setupUIAppearanceIfNeeded() {
///         if didSetupUIAppearance {
///             return
///         }
///         didSetupUIAppearance = true
///
///         let uiAppearance = UICollectionView.appearance(whenContainedInInstancesOf: [DummyMarkOnlyUIViewControllerSubclass.self])
///         uiAppearance.isScrollEnabled = false
///     }
/// }
///
/// private final class DummyMarkOnlyUIViewControllerSubclass: UIViewController {}
/// ```
/// Without using `UIAppearanceBoundaryContainerView` every `UICollectionView` in the app will have scroll disabled.
struct UIAppearanceBoundaryContainerView<BoundaryMarker, Content>: UIViewControllerRepresentable where Content: View, BoundaryMarker: UIViewController {
    private let boundaryMarker: () -> BoundaryMarker
    private let content: () -> Content

    /// Convenience constructor to avoid explicit generic specialization by the caller.
    init(
        boundaryMarker: @escaping () -> BoundaryMarker,
        content: @escaping () -> Content
    ) {
        self.boundaryMarker = boundaryMarker
        self.content = content
    }

    func makeUIViewController(context: Context) -> BoundaryMarker {
        let containerController = boundaryMarker()
        let hostingController = UIHostingController(rootView: content())
        containerController.addChild(hostingController)

        let containerView = containerController.view!
        let hostingView = hostingController.view!
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        hostingController.didMove(toParent: containerController)

        return containerController
    }

    func updateUIViewController(_ uiViewController: BoundaryMarker, context: Context) {}
}

// MARK: - Convenience extensions

extension UIAppearanceBoundaryContainerView {
    /// Convenience constructor to avoid explicit constructor call and generic specialization by the caller.
    init(
        boundaryMarker: BoundaryMarker.Type,
        content: @escaping () -> Content
    ) {
        self.init(boundaryMarker: boundaryMarker.init, content: content)
    }
}
