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

    var body: some View {
        Button(
            action: viewModel.tap,
            label: {
                HStack(spacing: 4) {
                    leadingItem
                        .frame(width: 20, height: 20)
                    Text(viewModel.model.title)
                        .font(Fonts.Bold.subheadline)
                        .foregroundStyle(Colors.Text.primary1)
                }
            }
        )
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .background(Colors.Background.action)
        .cornerRadiusContinuous(10)
        .disabled(viewModel.presentationState == .loading)
    }

    @ViewBuilder
    private var leadingItem: some View {
        switch viewModel.presentationState {
        case .initial, .idle:
            buttonIcon
        case .loading:
            progressView
        }
    }

    private var buttonIcon: some View {
        viewModel.model.icon.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(Colors.Icon.primary1)
    }

    private var progressView: some View {
        ProgressView()
            .tint(Colors.Icon.informative)
            .animation(.default, value: viewModel.presentationState)
    }
}
