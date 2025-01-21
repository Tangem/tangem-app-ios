//
//  ActionButtonsTokenSelectItemView.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsTokenSelectItemView: View {
    private let model: ActionButtonsTokenSelectorItem
    private let action: () -> Void
    private var isLoading: Bool {
        // the model is loading if one of balances is loading
        switch (model.balance, model.fiatBalance) {
        case (.loading, _), (_, .loading): true
        default: false
        }
    }

    init(model: ActionButtonsTokenSelectorItem, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    private let iconSize = CGSize(width: 36, height: 36)

    var body: some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: model.tokenIconInfo, size: iconSize)
                .saturation(model.isDisabled ? 0 : 1)

            infoView
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .disabled(model.isDisabled || isLoading)
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
            Text(model.name)
                .style(
                    Fonts.Bold.subheadline,
                    color: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                )

            Spacer(minLength: 4)

            LoadableTokenBalanceView(
                state: model.fiatBalance,
                style: .init(
                    font: Fonts.Regular.subheadline,
                    textColor: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                ),
                loader: .init(size: .init(width: 40, height: 12))
            )
        }
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            Text(model.symbol)
                .style(
                    Fonts.Regular.caption1,
                    color: Colors.Text.tertiary
                )

            Spacer(minLength: 4)

            LoadableTokenBalanceView(
                state: model.balance,
                style: .init(
                    font: Fonts.Bold.caption1,
                    textColor: model.isDisabled ? Colors.Text.disabled : Colors.Text.tertiary
                ),
                loader: .init(size: .init(width: 40, height: 12))
            )
        }
    }
}
