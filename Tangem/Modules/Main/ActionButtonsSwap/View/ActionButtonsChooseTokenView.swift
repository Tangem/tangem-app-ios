//
//  ActionButtonsChooseTokenView.swift
//  TangemApp
//
//  Created by Viacheslav E. on 18.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsChooseTokenView: View {
    @State private var size = CGSize.zero
    @Binding var selectedToken: ActionButtonsTokenSelectorItem?

    let field: Field

    var title: String {
        switch field {
        case .from: Localization.swappingFromTitle
        case .to: Localization.swappingToTitle
        }
    }

    var youWant: String {
        switch field {
        case .from: Localization.actionButtonsYouWantToSwap
        case .to: Localization.actionButtonsYouWantToReceive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text(title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                Spacer()
                if field == .from, selectedToken != nil {
                    Button(
                        action: { selectedToken = nil },
                        label: {
                            Text(Localization.manageTokensRemove)
                                .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                        }
                    )
                }
            }
            if let selectedToken {
                ActionButtonsTokenSelectItemView(model: selectedToken, action: {})
            } else {
                HStack {
                    Assets.emptyTokenList.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Colors.Icon.inactive)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localization.actionButtonsSwapChooseToken)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(youWant)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }
                }
            }
        }
        .padding(.init(top: 14, leading: 12, bottom: 14, trailing: 12))
        .background(Colors.Background.action)
        .cornerRadiusContinuous(14)
    }
}

extension ActionButtonsChooseTokenView {
    enum Field {
        case from
        case to
    }
}

#if DEBUG

#Preview {
    ZStack {
        Colors.Background.tertiary
        VStack {
            Group {
                ActionButtonsChooseTokenView(
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
                    ),
                    field: .to
                )
                ActionButtonsChooseTokenView(selectedToken: .constant(nil), field: .to)
                ActionButtonsChooseTokenView(selectedToken: .constant(nil), field: .from)
            }
        }
    }
}

#endif
