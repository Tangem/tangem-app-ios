//
//  OrganizeTokensContainerView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensContainerView: View {
    private static var didSetupUIAppearance = false

    private let viewModel: OrganizeTokensViewModel

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationView {
                    organizeTokensView
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
            } else {
                UIAppearanceBoundaryContainerView(boundaryMarker: OrganizeTokensContainerViewUIAppearanceBoundaryMarker.self) {
                    NavigationView {
                        organizeTokensView
                            .onAppear { Self.setupUIAppearanceIfNeeded() }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .vertical)
    }

    @ViewBuilder
    private var organizeTokensView: some View {
        OrganizeTokensView(viewModel: viewModel)
            .navigationTitle(Localization.organizeTokensTitle)
            .navigationBarTitleDisplayMode(.inline)
    }

    init(
        viewModel: OrganizeTokensViewModel
    ) {
        self.viewModel = viewModel
    }

    @available(iOS, obsoleted: 16.0, message: "Use native 'toolbarBackground(_:for:)' instead")
    private static func setupUIAppearanceIfNeeded() {
        if #unavailable(iOS 16.0), !didSetupUIAppearance {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()

            let uiAppearance = UINavigationBar.appearance(
                whenContainedInInstancesOf: [OrganizeTokensContainerViewUIAppearanceBoundaryMarker.self]
            )
            uiAppearance.compactAppearance = navBarAppearance
            uiAppearance.standardAppearance = navBarAppearance
            uiAppearance.scrollEdgeAppearance = navBarAppearance
            if #available(iOS 15.0, *) {
                uiAppearance.compactScrollEdgeAppearance = navBarAppearance
            }

            didSetupUIAppearance = true
        }
    }
}

// MARK: - Previews

struct OrganizeTokensContainerView_Preview: PreviewProvider {
    private static let previewProvider = OrganizeTokensPreviewProvider()

    static var previews: some View {
        let viewModels = [
            previewProvider.multipleSections(),
            previewProvider.singleMediumSection(),
            previewProvider.singleSmallSection(),
        ]

        Group {
            ForEach(viewModels.indexed(), id: \.0.self) { index, sections in
                OrganizeTokensContainerView(
                    viewModel: .init(
                        coordinator: OrganizeTokensCoordinator(),
                        sections: sections
                    )
                )
            }
        }
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Auxiliary types

private class OrganizeTokensContainerViewUIAppearanceBoundaryMarker: UIViewController {}
