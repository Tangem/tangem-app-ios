//
//  MarketsTokenDetailsExchangesListContainerView.swift
//  Tangem
//
//  Created by Andrew Son on 04.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsExchangesListContainerView: View {
    private static var didSetupUIAppearance = false

    private let viewModel: MarketsTokenDetailsExchangesListViewModel

    var body: some View {
        if #available(iOS 16.0, *) {
            exchangesListView
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            UIAppearanceBoundaryContainerView(boundaryMarker: MarketsTokenDetailsExchangesListViewUIAppearanceBoundaryMarker.self) {
                exchangesListView
                    .onAppear {
                        Self.setupUIAppearanceIfNeeded()
                    }
            }
        }
    }

    private var exchangesListView: some View {
        MarketsTokenDetailsExchangesListView(viewModel: viewModel)
    }

    init(viewModel: MarketsTokenDetailsExchangesListViewModel) {
        self.viewModel = viewModel
    }

    @available(iOS, obsoleted: 16.0, message: "Use native 'toolbarBackground(_:for:)' instead")
    private static func setupUIAppearanceIfNeeded() {
        if #unavailable(iOS 16.0), !didSetupUIAppearance {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()

            let uiAppearance = UINavigationBar.appearance(
                whenContainedInInstancesOf: [MarketsTokenDetailsExchangesListViewUIAppearanceBoundaryMarker.self]
            )
            uiAppearance.compactAppearance = navBarAppearance
            uiAppearance.standardAppearance = navBarAppearance
            uiAppearance.scrollEdgeAppearance = navBarAppearance
            uiAppearance.compactScrollEdgeAppearance = navBarAppearance

            didSetupUIAppearance = true
        }
    }
}

private class MarketsTokenDetailsExchangesListViewUIAppearanceBoundaryMarker: UIViewController {}
