//
//  ManageTokensCustomItemView.swift
//  Tangem
//
//  Created by skibinalexander on 02.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensCustomItemView: View {
    @ObservedObject var viewModel: ManageTokensCustomItemViewModel

    private let iconSize = CGSize(bothDimensions: 46)

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                if let tokenIconInfo = viewModel.tokenIconInfo {
                    TokenIcon(
                        name: tokenIconInfo.name,
                        imageURL: tokenIconInfo.imageURL,
                        blockchainIconName: tokenIconInfo.blockchainIconName,
                        isCustom: tokenIconInfo.isCustom,
                        size: iconSize
                    )
                    .padding(.trailing, 12)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(viewModel.tokenItem.name)
                            .lineLimit(1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.tokenItem.currencySymbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }

                    HStack(spacing: 4) {
                        Text(Localization.manageTokensCustom)
                            .lineLimit(1)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }

                Spacer(minLength: 24)

                manageButtonView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .animation(nil) // Disable animations on scroll reuse
    }

    @ViewBuilder
    private func manageButtonView() -> some View {
        ZStack {
            Button {
                viewModel.didTapAction(viewModel.tokenItem)
            } label: {
                EditButtonView()
            }
        }
    }
}

private struct EditButtonView: View {
    var body: some View {
        TextButtonView(text: Localization.manageTokensEdit, foreground: Colors.Text.primary1, background: Colors.Button.secondary)
    }
}

private struct TextButtonView: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .style(Fonts.Bold.caption1, color: foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}
