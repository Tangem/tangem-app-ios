//
//  ActionButtonsTokenSelectItemView.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsTokenSelectItemView: View {
    @StateObject private var viewModel: ActionButtonsTokenSelectItemViewModel

    private let action: () -> Void

    init(model: ActionButtonsTokenSelectorItem, action: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: .init(model: model))
        self.action = action
    }

    private let iconSize = CGSize(width: 36, height: 36)

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: viewModel.model.tokenIconInfo, size: iconSize)
                .saturation(viewModel.isDisabled ? 0 : 1)

            infoView
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .disabled(viewModel.isDisabled)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            topInfoView

            bottomInfoView
        }
        .lineLimit(1)
    }

    private var topInfoView: some View {
        HStack(spacing: .zero) {
            Text(viewModel.model.infoProvider.tokenItem.name)
                .style(
                    Fonts.Bold.subheadline,
                    color: viewModel.model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                )

            Spacer(minLength: 4)

            LoadableTextView(
                state: viewModel.fiatBalanceState,
                font: Fonts.Bold.subheadline,
                textColor: viewModel.model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12),
                isSensitiveText: true
            )
        }
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            Text(viewModel.model.infoProvider.tokenItem.currencySymbol)
                .style(
                    Fonts.Regular.caption1,
                    color: Colors.Text.tertiary
                )

            Spacer(minLength: 4)

            LoadableTextView(
                state: viewModel.balanceState,
                font: Fonts.Regular.caption1,
                textColor: viewModel.model.isDisabled ? Colors.Text.disabled : Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12),
                isSensitiveText: true
            )
        }
    }
}
