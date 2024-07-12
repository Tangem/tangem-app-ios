//
//  MarketsRatingHeaderView.swift
//  Tangem
//
//  Created by skibinalexander on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsRatingHeaderView: View {
    @ObservedObject var viewModel: MarketsRatingHeaderViewModel

    var body: some View {
        HStack {
            orderButtonView

            Spacer()

            timeIntervalPicker
        }
    }

    private var orderButtonView: some View {
        Button {
            viewModel.onOrderActionButtonDidTap()
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.marketListOrderType.description)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Assets
                    .chevronDownMini
                    .image
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Colors.Background.secondary)
            )
        }
    }

    private var timeIntervalPicker: some View {
        VStack(alignment: .trailing, spacing: .zero) {
            MarketsPickerView(
                marketPriceIntervalType: $viewModel.marketPriceIntervalType,
                options: viewModel.marketPriceIntervalTypeOptions,
                shouldStretchToFill: false,
                titleFactory: { $0.tokenDetailsNameLocalized }
            )
        }
    }
}
