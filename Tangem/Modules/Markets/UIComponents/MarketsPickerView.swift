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
    let shouldStretchToFill: Bool
    let titleFactory: (MarketsPriceIntervalType) -> String

    var body: some View {
        SegmentedPickerView(
            selection: $marketPriceIntervalType,
            options: options,
            shouldStretchToFill: shouldStretchToFill,
            selectionView: selectionView,
            segmentContent: { option, _ in
                segmentView(title: titleFactory(option), isSelected: marketPriceIntervalType == option)
                    .animation(.none, value: marketPriceIntervalType)
            }
        )
        .insets(Constants.insets)
        .segmentedControlSlidingAnimation(.easeInOut)
        .segmentedControl(interSegmentSpacing: Constants.interSegmentSpacing)
        .background(Colors.Button.secondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.containerCornerRadius))
    }

    private func segmentView(title: String, isSelected: Bool) -> some View {
        ZStack(alignment: .center) {
            Text(title)
                .font(Fonts.Bold.footnote)
                .foregroundStyle(Colors.Text.primary1)
                .opacity(isSelected ? 1.0 : 0.0)

            Text(title)
                .font(Fonts.Regular.footnote)
                .foregroundStyle(Colors.Text.primary1)
                .opacity(isSelected ? 0.0 : 1.0)
        }
        .animation(.default, value: isSelected)
        .lineLimit(1)
        .padding(.vertical, 2)
        .padding(.horizontal, 12)
    }

    private var selectionView: some View {
        Colors.Background.primary
            .clipShape(RoundedRectangle(cornerRadius: Constants.selectionViewCornerRadius))
    }
}

private extension MarketsPickerView {
    enum Constants {
        static let insets: EdgeInsets = .init(top: 2, leading: 2, bottom: 2, trailing: 2)
        static let interSegmentSpacing: CGFloat = 0
        static let containerCornerRadius: CGFloat = 8
        // We need to use an odd value, otherwise the rounding curvature of the selection
        // will be noticeably different from the background rounding curvature
        static let selectionViewCornerRadius: CGFloat = 7
    }
}

#Preview {
    struct MarketsPickerPreviewView: View {
        @State private var firstInterval = MarketsPriceIntervalType.day
        @State private var secondInterval = MarketsPriceIntervalType.day
        @State private var thirdInterval = MarketsPriceIntervalType.day

        var body: some View {
            VStack(spacing: 30) {
                MarketsPickerView(
                    marketPriceIntervalType: $firstInterval,
                    options: [.day, .week, .month],
                    shouldStretchToFill: false,
                    titleFactory: { $0.marketsListId }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: false,
                    titleFactory: { $0.rawValue }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: true,
                    titleFactory: { $0.rawValue }
                )
                .padding(.horizontal, 16)
            }
        }
    }

    return MarketsPickerPreviewView()
        .background(Colors.Background.primary)
}
