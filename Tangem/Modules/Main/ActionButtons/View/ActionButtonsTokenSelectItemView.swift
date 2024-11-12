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
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .disabled(model.isDisabled)
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

            Spacer(minLength: 4)

            SensitiveText(model.fiatBalance)
        }
        .style(
            Fonts.Bold.subheadline,
            color: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
        )
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            Text(model.symbol)
                .style(
                    Fonts.Regular.footnote,
                    color: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                )

            Spacer(minLength: 4)

            SensitiveText(model.balance)
                .style(
                    Fonts.Regular.footnote,
                    color: model.isDisabled ? Colors.Text.disabled : Colors.Text.tertiary
                )
        }
    }
}
