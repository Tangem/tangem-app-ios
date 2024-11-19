//
//  OnrampView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampView: View {
    @ObservedObject var viewModel: OnrampViewModel

    let transitionService: SendTransitionService
    let namespace: Namespace

    var body: some View {
        GroupedScrollView(spacing: 14) {
            OnrampAmountView(
                viewModel: viewModel.onrampAmountViewModel,
                namespace: .init(id: namespace.id, names: namespace.names)
            )

            paymentSection
        }
    }

    private var paymentSection: some View {
        GroupedSection(viewModel.paymentState) { state in
            switch state {
            case .loading:
                LoadingProvidersRow()
            case .loaded(let data):
                OnrampProvidersCompactView(data: data)
            }
        }
        .innerContentPadding(14)
        .backgroundColor(Colors.Background.action)
        .animation(.default, value: viewModel.paymentState)
    }
}

extension OnrampView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}
