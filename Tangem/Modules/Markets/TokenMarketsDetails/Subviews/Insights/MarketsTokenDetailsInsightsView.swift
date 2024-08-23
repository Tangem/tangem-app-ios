//
//  MarketsTokenDetailsInsightsView.swift
//  Tangem
//
//  Created by Andrew Son on 08/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct MarketsTokenDetailsInsightsView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsInsightsViewModel

    @State private var gridWidth: CGFloat = .zero
    @State private var firstItemWidth: CGFloat = .zero

    private var itemWidth: CGFloat {
        let halfSizeWidth = gridWidth / 2 - Constants.itemsSpacing
        return halfSizeWidth > firstItemWidth ? halfSizeWidth : firstItemWidth
    }

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: itemWidth), spacing: Constants.itemsSpacing, alignment: .leading)]
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Localization.marketsTokenDetailsInsights)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                MarketsPickerView(
                    marketPriceIntervalType: $viewModel.selectedInterval,
                    options: viewModel.availableIntervals,
                    shouldStretchToFill: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.tokenDetailsNameLocalized }
                )
            }
            .padding(.bottom, 6)

            LazyVGrid(columns: gridItems, alignment: .center, spacing: 16, content: {
                ForEach(viewModel.records.indexed(), id: \.0) { index, info in
                    TokenMarketsDetailsStatisticsRecordView(
                        title: info.title,
                        message: info.recordData,
                        infoButtonAction: {
                            viewModel.showInfoBottomSheet(for: info.type)
                        },
                        containerWidth: gridWidth
                    )
                    .readGeometry(\.size.width, onChange: { value in
                        if value > firstItemWidth {
                            firstItemWidth = value
                        }
                    })
                    .transition(.opacity)
                }
            })
            .readGeometry(\.size.width, bindTo: $gridWidth)
        }
        .animation(.default, value: viewModel.selectedInterval)
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}

extension MarketsTokenDetailsInsightsView {
    enum Constants {
        static let itemsSpacing: CGFloat = 12
    }
}

extension MarketsTokenDetailsInsightsView {
    enum RecordType: String, Identifiable, MarketsTokenDetailsInfoDescriptionProvider {
        case buyers
        case buyPressure
        case holdersChange
        case liquidity

        var id: String { rawValue }

        var title: String {
            switch self {
            case .buyers: return Localization.marketsTokenDetailsExperiencedBuyers
            case .buyPressure: return Localization.marketsTokenDetailsBuyPressure
            case .holdersChange: return Localization.marketsTokenDetailsHolders
            case .liquidity: return Localization.marketsTokenDetailsLiquidity
            }
        }

        var infoDescription: String {
            switch self {
            case .buyers: return Localization.marketsTokenDetailsExperiencedBuyersDescription
            case .buyPressure: return Localization.marketsTokenDetailsBuyPressureDescription
            case .holdersChange: return Localization.marketsTokenDetailsHoldersDescription
            case .liquidity: return Localization.marketsTokenDetailsLiquidityDescription
            }
        }
    }

    struct RecordInfo: Identifiable {
        let type: RecordType
        let recordData: String

        var id: String {
            "\(type.id) - \(recordData)"
        }

        var title: String {
            type.title
        }
    }
}

#Preview {
    let records: [MarketsTokenDetailsInsightsView.RecordInfo] = [
        .init(type: .buyers, recordData: "+44"),
        .init(type: .buyPressure, recordData: "-$400"),
        .init(type: .holdersChange, recordData: "+100"),
        .init(type: .liquidity, recordData: "+445,9K"),
    ]
    let insights = CurrentValueSubject<TokenMarketsDetailsInsights?, Never>(nil)

    return MarketsTokenDetailsInsightsView(
        viewModel: .init(
            tokenSymbol: "BTC",
            insights: .init(dto: MarketsDTO.Coins.Insights(
                holdersChange: [:],
                liquidityChange: [:],
                buyPressureChange: [:],
                experiencedBuyerChange: [:]
            ))!,
            insightsPublisher: insights,
            notationFormatter: .init(),
            infoRouter: nil
        )
    )
}
