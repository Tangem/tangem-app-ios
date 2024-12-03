//
//  ActionButtonView.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonView<ViewModel: ActionButtonViewModel>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.isEnabled) var isEnabled

    private var isDisabled: Bool {
        !isEnabled || viewModel.isDisabled
    }

    var body: some View {
        HStack(spacing: 4) {
            leadingItem
                .frame(width: 20, height: 20)
            Text(viewModel.model.title)
                .style(
                    Fonts.Bold.subheadline,
                    color: isDisabled ? Colors.Text.disabled : Colors.Text.primary1
                )
        }
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .background(Colors.Background.action)
        .cornerRadiusContinuous(10)
        .onTapGesture(perform: viewModel.tap)
        .bindAlert($viewModel.alert)
    }

    @ViewBuilder
    private var leadingItem: some View {
        switch viewModel.viewState {
        case .initial, .idle, .disabled:
            buttonIcon
        case .loading:
            progressView
        }
    }

    private var buttonIcon: some View {
        viewModel.model.icon.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(isDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
    }

    private var progressView: some View {
        ProgressView()
            .tint(Colors.Icon.informative)
            .animation(.default, value: viewModel.viewState)
    }
}
