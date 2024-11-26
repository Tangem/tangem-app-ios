//
//  ActionButtonsChooseTokenView.swift
//  TangemApp
//
//  Created by Viacheslav E. on 18.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsChooseTokenView: View {
    @StateObject private var viewModel: ActionButtonsChooseTokenViewModel

    @Binding var selectedToken: ActionButtonsTokenSelectorItem?

    init(field: ActionButtonsChooseTokenViewModel.Field, selectedToken: Binding<ActionButtonsTokenSelectorItem?>) {
        _selectedToken = selectedToken
        _viewModel = StateObject(wrappedValue: .init(field: field))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 29) {
            header

            mainContent
        }
        .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 14))
        .background(Colors.Background.action)
        .cornerRadiusContinuous(14)
        .onChange(of: selectedToken) { newValue in
            viewModel.selectedToken = newValue
        }
    }

    private var header: some View {
        HStack {
            Text(viewModel.title)
                .frame(height: 18)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            Spacer()

            removeSourceButton
        }
    }

    @ViewBuilder
    private var removeSourceButton: some View {
        if viewModel.isRemoveButtonVisible {
            Button(
                action: { selectedToken = nil },
                label: {
                    Text(Localization.manageTokensRemove)
                        .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                }
            )
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if let selectedToken {
            ActionButtonsTokenSelectItemView(model: selectedToken, action: {})
                .background(Colors.Background.action)
        } else {
            Text(viewModel.description)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity)
                .padding(.init(top: 12, leading: 33, bottom: 12, trailing: 33))
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: .init(lineWidth: 1, dash: [4], dashPhase: 6))
                        .foregroundStyle(Colors.Icon.informative)
                }
        }
    }
}

#if DEBUG

#Preview {
    ZStack {
        Colors.Background.tertiary
        VStack {
            Group {
                ActionButtonsChooseTokenView(
                    field: .destination,
                    selectedToken: .constant(
                        .init(
                            id: 0,
                            tokenIconInfo: .init(
                                name: "",
                                blockchainIconName: "",
                                imageURL: nil,
                                isCustom: false,
                                customTokenColor: .black
                            ),
                            name: "Ethereum",
                            symbol: "ETH",
                            balance: "1 ETH",
                            fiatBalance: "88000$",
                            isDisabled: false,
                            isLoading: false,
                            walletModel: .mockETH
                        )
                    )
                )
                ActionButtonsChooseTokenView(field: .source, selectedToken: .constant(nil))
                ActionButtonsChooseTokenView(field: .destination, selectedToken: .constant(nil))
            }
        }
    }
}

#endif
