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
        .disabled(model.isDisabled || model.isLoading)
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

            LoadableTextView(
                state: model.isLoading ? .loading : .loaded(text: model.fiatBalance),
                font: Fonts.Bold.subheadline,
                textColor: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12),
                isSensitiveText: true
            )
        }
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            Text(model.symbol)
                .style(
                    Fonts.Regular.caption1,
                    color: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                )

            Spacer(minLength: 4)

            LoadableTextView(
                state: model.isLoading ? .loading : .loaded(text: model.balance),
                font: Fonts.Regular.caption1,
                textColor: model.isDisabled ? Colors.Text.disabled : Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12),
                isSensitiveText: true
            )
        }
    }
}
