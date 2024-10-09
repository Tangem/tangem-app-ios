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
    let viewWidth: CGFloat

    private var itemWidth: CGFloat {
        max(0, (viewWidth - Constants.itemsSpacing - Constants.backgroundHorizontalPadding * 2) / 2)
    }

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: itemWidth), spacing: Constants.itemsSpacing, alignment: .topLeading)]
    }

    var body: some View {
        VStack(spacing: .zero) {
            header

            LazyVGrid(columns: gridItems, alignment: .center, spacing: 16, content: {
                ForEach(viewModel.records.indexed(), id: \.0) { index, info in
                    MarketsTokenDetailsStatisticsRecordView(
                        title: info.title,
                        message: info.recordData,
                        trend: info.trend,
                        infoButtonAction: {
                            viewModel.showInfoBottomSheet(for: info.type)
                        }
                    )
                    .frame(minWidth: itemWidth, alignment: .leading)
                }
            })
            .drawingGroup()
            .padding(.vertical, Constants.itemsSpacing)
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero, horizontalPadding: Constants.backgroundHorizontalPadding)
    }

    private var header: some View {
        HStack {
            if viewModel.shouldShowHeaderInfoButton {
                Button(action: viewModel.showInsightsSheetInfo) {
                    HStack(spacing: 4) {
                        headerLabel

                        Assets.infoCircle16.image
                            .renderingMode(.template)
                            .foregroundStyle(Colors.Icon.informative)
                    }
                }
            } else {
                headerLabel
            }

            Spacer()

            MarketsPickerView(
                marketPriceIntervalType: $viewModel.selectedInterval,
                options: viewModel.availableIntervals,
                shouldStretchToFill: false,
                isDisabled: false,
                style: .init(textVerticalPadding: 2),
                titleFactory: { $0.tokenDetailsNameLocalized }
            )
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var headerLabel: some View {
        Text(Localization.marketsTokenDetailsInsights)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }
}

extension MarketsTokenDetailsInsightsView {
    enum Constants {
        static let itemsSpacing: CGFloat = 12
        static let backgroundHorizontalPadding: CGFloat = 14
    }
}

extension MarketsTokenDetailsInsightsView {
    enum RecordType: String, Identifiable, MarketsTokenDetailsInfoDescriptionProvider {
        case buyers
        case buyPressure
        case holdersChange
        case liquidity

        var id: String { rawValue }

        var titleShort: String {
            switch self {
            case .buyers: return Localization.marketsTokenDetailsExperiencedBuyers
            case .buyPressure: return Localization.marketsTokenDetailsBuyPressure
            case .holdersChange: return Localization.marketsTokenDetailsHolders
            case .liquidity: return Localization.marketsTokenDetailsLiquidity
            }
        }

        var titleFull: String {
            switch self {
            case .buyers: return Localization.marketsTokenDetailsExperiencedBuyersFull
            case .buyPressure: return Localization.marketsTokenDetailsBuyPressureFull
            case .holdersChange: return Localization.marketsTokenDetailsHoldersFull
            case .liquidity: return Localization.marketsTokenDetailsLiquidityFull
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
        let trend: MarketsTokenDetailsStatisticsRecordView.Trend?

        var id: String {
            "\(type.id) - \(recordData)"
        }

        var title: String {
            type.titleShort
        }
    }
}

#Preview {
    let insights = CurrentValueSubject<MarketsTokenDetailsInsights?, Never>(nil)

    return MarketsTokenDetailsInsightsView(
        viewModel: .init(
            tokenSymbol: "BTC",
            insights: .init(dto: MarketsDTO.Coins.Insights(
                holdersChange: [
                    "24h": nil,
                    "1w": 0,
                    "1m": nil,
                ],
                liquidityChange: [
                    "24h": -5704467.269745085,
                    "1w": -5714908.849255774,
                    "1m": -5714908.849255774,
                ],
                buyPressureChange: [
                    "24h": 1379091.5783956223,
                    "1w": -334647.79027640104,
                    "1m": -4501466.504872012,
                ],
                experiencedBuyerChange: [
                    "24h": 0,
                    "1w": nil,
                    "1m": nil,
                ],
                networks: nil
            ))!,
            insightsPublisher: insights,
            notationFormatter: .init(),
            infoRouter: nil
        ),
        viewWidth: 300
    )
}
