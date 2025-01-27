//
//  ExpressTokenItemView.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpressTokenItemView: View {
    private let viewModel: ExpressTokenItemViewModel

    private let iconSize = CGSize(width: 36, height: 36)

    init(viewModel: ExpressTokenItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.itemDidTap) {
            HStack(spacing: 12) {
                TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: iconSize)
                    .saturation(viewModel.isDisable ? 0 : 1)

                infoView
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isDisable)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: .zero) {
                Text(viewModel.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: viewModel.isDisable ? Colors.Text.tertiary : Colors.Text.primary1
                    )

                Spacer(minLength: 4)

                SensitiveText(viewModel.fiatBalance)
                    .style(
                        Fonts.Regular.subheadline,
                        color: viewModel.isDisable ? Colors.Text.tertiary : Colors.Text.primary1
                    )
            }

            HStack(spacing: .zero) {
                Text(viewModel.symbol)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 4)

                SensitiveText(viewModel.balance)
                    .style(
                        Fonts.Regular.footnote,
                        color: viewModel.isDisable ? Colors.Text.disabled : Colors.Text.tertiary
                    )
            }
        }
        .lineLimit(1)
    }
}

struct ExpressTokenItemView_Previews: PreviewProvider {
    static let viewModels = [
        ExpressTokenItemViewModel(
            id: "Bitcoin",
            tokenIconInfo: TokenIconInfo(
                name: "",
                blockchainIconName: "bitcoin",
                imageURL: IconURLBuilder().tokenIconURL(id: "", size: .large),
                isCustom: false,
                customTokenColor: Color.red
            ),
            name: "Bitcoin",
            symbol: "BTC",
            balance: "3.543 BTC",
            fiatBalance: "$3.543",
            isDisable: false,
            itemDidTap: {}
        ), ExpressTokenItemViewModel(
            id: "Ethereum",
            tokenIconInfo: TokenIconInfo(
                name: "",
                blockchainIconName: "ethereum",
                imageURL: IconURLBuilder().tokenIconURL(id: "tether", size: .large),
                isCustom: false,
                customTokenColor: Color.red
            ),
            name: "Ethereum",
            symbol: "ETH",
            balance: "3.543 ETH",
            fiatBalance: "$3.543",
            isDisable: false,
            itemDidTap: {}
        ), ExpressTokenItemViewModel(
            id: "Tether",
            tokenIconInfo: TokenIconInfo(
                name: "",
                blockchainIconName: "ethereum",
                imageURL: IconURLBuilder().tokenIconURL(id: "dai", size: .large),
                isCustom: false,
                customTokenColor: Color.red
            ),
            name: "Dai",
            symbol: "DAI",
            balance: "3.543 DAI",
            fiatBalance: "$3.543",
            isDisable: true,
            itemDidTap: {}
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            GroupedSection(viewModels) {
                ExpressTokenItemView(viewModel: $0)
            }
        }
    }
}
