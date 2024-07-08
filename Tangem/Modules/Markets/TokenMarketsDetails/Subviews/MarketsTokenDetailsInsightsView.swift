//
//  MarketsTokenDetailsInsightsView.swift
//  Tangem
//
//  Created by Andrew Son on 08/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

protocol MarketsTokenDetailsBottomSheetRouter {
    func openInfoBottomSheet(title: String, message: String)
}

struct MarketsTokenDetailsInsightsViewModel {
    let records: [MarketsTokenDetailsInsightsView.RecordInfo]
    let infoRouter: MarketsTokenDetailsBottomSheetRouter?

    func showInfoBottomSheet(for recordType: MarketsTokenDetailsInsightsView.RecordType) {
        infoRouter?.openInfoBottomSheet(title: recordType.title, message: recordType.infoDescription)
    }
}

struct MarketsTokenDetailsInsightsView: View {
    enum RecordType: String, Identifiable {
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
        let data: String
        let infoButtonAction: (RecordType) -> Void

        var id: String {
            "\(type.id) - \(data)"
        }

        var title: String {
            type.title
        }
    }

    let recordsInfo: [RecordInfo]

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
        VStack(spacing: 0) {
            HStack {
                Text(Localization.marketsTokenDetailsInsights)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                MarketsPickerView(
                    marketPriceIntervalType: .constant(.day),
                    options: [.day, .month, .year],
                    shouldStretchToFill: false,
                    titleFactory: { $0.rawValue }
                )
            }

            LazyVGrid(columns: gridItems, alignment: .center, spacing: 10, content: {
                ForEach(recordsInfo.indexed(), id: \.1.id) { index, info in
                    TokenMarketsDetailsStatisticsRecordView(
                        title: info.title,
                        message: info.data,
                        infoButtonAction: {
                            info.infoButtonAction(info.type)
                        },
                        containerWidth: gridWidth
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
        .padding(.horizontal, 16)
        .defaultRoundedBackground()
    }
}

extension MarketsTokenDetailsInsightsView {
    enum Constants {
        static let itemsSpacing: CGFloat = 12
    }
}

#Preview {
    let records: [MarketsTokenDetailsInsightsView.RecordInfo] = [
        .init(type: .buyers, data: "+44", infoButtonAction: { _ in }),
        .init(type: .buyPressure, data: "-$400", infoButtonAction: { _ in }),
        .init(type: .holdersChange, data: "+100", infoButtonAction: { _ in }),
        .init(type: .liquidity, data: "+445,9K", infoButtonAction: { _ in }),
    ]
    return MarketsTokenDetailsInsightsView(recordsInfo: records)
}
