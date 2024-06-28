//
//  MarketsPickerView.swift
//  Tangem
//
//  Created by Andrew Son on 26/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPickerView: View {
    @Binding var marketPriceIntervalType: MarketsPriceIntervalType

    let options: [MarketsPriceIntervalType]
    let titleFactory: (MarketsPriceIntervalType) -> String

    var body: some View {
        SegmentedPickerView(
            selection: $marketPriceIntervalType,
            options: options,
            selectionView: selectionView,
            segmentContent: { option, _ in
                segmentView(title: titleFactory(option), isSelected: marketPriceIntervalType == option)
                    .colorMultiply(Colors.Text.primary1)
                    .animation(.none, value: marketPriceIntervalType)
            }
        )
        .insets(Constants.insets)
        .segmentedControlSlidingAnimation(.default)
        .segmentedControl(interSegmentSpacing: Constants.interSegmentSpacing)
        .background(Colors.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.containerCornerRadius))
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

    private var selectionView: some View {
        Colors.Background.primary
            .clipShape(RoundedRectangle(cornerRadius: Constants.selectionViewCornerRadius))
    }
}

private extension MarketsPickerView {
    enum Constants {
        static let insets: EdgeInsets = .init(top: 2, leading: 2, bottom: 2, trailing: 2)
        static let interSegmentSpacing: CGFloat = 2
        static let containerCornerRadius: CGFloat = 8
        // We need to use an odd value, otherwise the rounding curvature of the selection
        // will be noticeably different from the background rounding curvature
        static let selectionViewCornerRadius: CGFloat = 7
    }
}

#Preview {
    @State var priceIntervalType: MarketsPriceIntervalType = .day
    @State var tokenPriceInterval: MarketsPriceIntervalType = .day

    return VStack(spacing: 30) {
        StatefulPreviewWrapper(priceIntervalType) { intervalType in
            MarketsPickerView(
                marketPriceIntervalType: intervalType,
                options: [.day, .week, .month],
                titleFactory: { $0.marketsListId }
            )
        }

        StatefulPreviewWrapper(tokenPriceInterval) { intervalType in
            MarketsPickerView(
                marketPriceIntervalType: intervalType,
                options: MarketsPriceIntervalType.allCases,
                titleFactory: { $0.tokenMarketsDetailsId }
            )
        }
    }
}
