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
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: iconSize)
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
            Text(viewModel.tokenName)
                .style(
                    Fonts.Bold.subheadline,
                    color: viewModel.getDisabledTextColor(for: .tokenName)
                )

            Spacer(minLength: 4)

            LoadableTextView(
                state: viewModel.fiatBalanceState,
                font: Fonts.Bold.subheadline,
                textColor: viewModel.getDisabledTextColor(for: .fiatBalance),
                loaderSize: .init(width: 40, height: 12),
                isSensitiveText: true
            )
        }
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            Text(viewModel.currencySymbol)
                .style(
                    Fonts.Regular.caption1,
                    color: Colors.Text.tertiary
                )

            Spacer(minLength: 4)

            LoadableTextView(
                state: viewModel.balanceState,
                font: Fonts.Regular.caption1,
                textColor: viewModel.getDisabledTextColor(for: .balance),
                loaderSize: .init(width: 40, height: 12),
                isSensitiveText: true
            )
        }
    }
}
