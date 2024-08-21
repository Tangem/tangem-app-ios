//
//  MarketsTokenDetailsMetricsView.swift
//  Tangem
//
//  Created by Andrew Son on 10/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsMetricsView: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    @State private var gridWidth: CGFloat = .zero
    @State private var firstItemWidth: CGFloat = .zero

    private var itemWidth: CGFloat {
        let halfSizeWidth = gridWidth / 2 - Constants.itemsSpacing
        return halfSizeWidth > firstItemWidth ? halfSizeWidth : firstItemWidth
    }

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: itemWidth), spacing: Constants.itemsSpacing, alignment: .topLeading)]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Localization.marketsTokenDetailsMetrics)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()
            }

            LazyVGrid(columns: gridItems, alignment: .center, spacing: 10, content: {
                ForEach(viewModel.records.indexed(), id: \.1.id) { index, info in
                    TokenMarketsDetailsStatisticsRecordView(
                        title: info.title,
                        message: info.recordData,
                        infoButtonAction: {
                            viewModel.showInfoBottomSheet(for: info.type)
                        },
                        containerWidth: gridWidth,
                        estimateTitleAndMessageSizes: false
                    )
                    .readGeometry(\.size.width, onChange: { value in
                        if value > firstItemWidth {
                            firstItemWidth = value
                        }
                    })
                    .padding(.vertical, 10)
                }
            })
            .readGeometry(\.size.width, bindTo: $gridWidth)
        }
        .animation(nil)
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}

extension MarketsTokenDetailsMetricsView {
    enum Constants {
        static let itemsSpacing: CGFloat = 12
    }
}

extension MarketsTokenDetailsMetricsView {
    enum RecordType: String, Identifiable, MarketsTokenDetailsInfoDescriptionProvider {
        case marketCapitalization
        case marketRating
        case tradingVolume
        case fullyDilutedValuation
        case circulatingSupply
        case totalSupply

        var id: String { rawValue }

        var title: String {
            switch self {
            case .marketCapitalization: return Localization.marketsTokenDetailsMarketCapitalization
            case .marketRating: return Localization.marketsTokenDetailsMarketRating
            case .tradingVolume: return Localization.marketsTokenDetailsTradingVolume
            case .fullyDilutedValuation: return Localization.marketsTokenDetailsFullyDilutedValuation
            case .circulatingSupply: return Localization.marketsTokenDetailsCirculatingSupply
            case .totalSupply: return Localization.marketsTokenDetailsTotalSupply
            }
        }

        var infoDescription: String {
            switch self {
            case .marketCapitalization: return Localization.marketsTokenDetailsMarketCapitalizationDescription
            case .marketRating: return Localization.marketsTokenDetailsMarketRatingDescription
            case .tradingVolume: return Localization.marketsTokenDetailsTradingVolume24hDescription
            case .fullyDilutedValuation: return Localization.marketsTokenDetailsFullyDilutedValuationDescription
            case .circulatingSupply: return Localization.marketsTokenDetailsCirculatingSupplyDescription
            case .totalSupply: return Localization.marketsTokenDetailsTotalSupplyDescription
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
    MarketsTokenDetailsMetricsView(
        viewModel: .init(
            metrics: .init(
                marketRating: 3,
                circulatingSupply: 112259808785.143,
                marketCap: 112234033891,
                volume24H: 42854017104,
                totalSupply: 112286364258.112,
                fullyDilutedValuation: 112234033891
            ),
            infoRouter: nil
        )
    )
}
