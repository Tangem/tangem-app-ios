//
//  ActionButtonsTokenSelectItemView.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsTokenSelectorItem: Identifiable, Equatable {
    let id: Int
    let tokenIconInfo: TokenIconInfo
    let name: String
    let symbol: String
    let balance: String
    let fiatBalance: String
    let isDisabled: Bool
    let walletModel: WalletModel
}

struct ActionButtonsTokenSelectItemView: View {
    private let model: ActionButtonsTokenSelectorItem

    init(model: ActionButtonsTokenSelectorItem) {
        self.model = model
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
        .disabled(model.isDisabled)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: .zero) {
                Text(model.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                    )

                Spacer(minLength: 4)

                SensitiveText(model.fiatBalance)
                    .style(
                        Fonts.Regular.subheadline,
                        color: model.isDisabled ? Colors.Text.tertiary : Colors.Text.primary1
                    )
            }

            HStack(spacing: .zero) {
                Text(model.symbol)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 4)

                SensitiveText(model.balance)
                    .style(
                        Fonts.Regular.footnote,
                        color: model.isDisabled ? Colors.Text.disabled : Colors.Text.tertiary
                    )
            }
        }
        .lineLimit(1)
    }
}
