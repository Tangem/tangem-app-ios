//
//  MarketsRatingHeaderView.swift
//  Tangem
//
//  Created by skibinalexander on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsRatingHeaderView: View {
    @ObservedObject var viewModel: MarketRatingHeaderViewModel

    private let insets: EdgeInsets = .init(top: 2, leading: 2, bottom: 2, trailing: 2)
    private let interSegmentSpacing: CGFloat = 2

    @State private var containerCornerRadius: CGFloat = 9

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
                RoundedRectangle(cornerRadius: containerCornerRadius)
                    .fill(Colors.Background.secondary)
            )
        }
    }

    private var timeIntervalPicker: some View {
        VStack(alignment: .trailing, spacing: .zero) {
            SegmentedPickerView(
                selection: $viewModel.marketPriceIntervalType,
                options: viewModel.marketPriceIntervalTypeOptions,
                selectionView: selectionView,
                segmentContent: { option, _ in
                    segmentView(title: option.description, isSelected: viewModel.marketPriceIntervalType == option)
                        .colorMultiply(Colors.Text.primary1)
                        .animation(.none, value: viewModel.marketPriceIntervalType)
                }
            )
            .insets(insets)
            .segmentedControlSlidingAnimation(.default)
            .segmentedControl(interSegmentSpacing: interSegmentSpacing)
            .background(Colors.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius))
        }
    }

    private var selectionView: some View {
        Colors.Background.primary
            .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius - 2))
    }

    private func segmentView(title: String, isSelected: Bool) -> some View {
        HStack(spacing: .zero) {
            Text(title)
                .font(isSelected ? Fonts.Bold.footnote : Fonts.Regular.footnote)
        }
        .lineLimit(1)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}
