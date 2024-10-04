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
    let isDisabled: Bool
    let style: SegmentedPicker<MarketsPriceIntervalType>.Style
    let titleFactory: (MarketsPriceIntervalType) -> String

    var body: some View {
        SegmentedPicker(
            selectedOption: $marketPriceIntervalType,
            options: options,
            shouldStretchToFill: shouldStretchToFill,
            isDisabled: isDisabled,
            style: style,
            titleFactory: titleFactory
        )
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
                    isDisabled: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.marketsListId }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: false,
                    isDisabled: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.rawValue }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: true,
                    isDisabled: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.rawValue }
                )
                .padding(.horizontal, 16)
            }
        }
    }

    return MarketsPickerPreviewView()
        .background(Colors.Background.primary)
}
