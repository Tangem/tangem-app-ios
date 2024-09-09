//
//  TokenMarketsDetailsStatisticsRecordView.swift
//  Tangem
//
//  Created by Andrew Son on 08/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsStatisticsRecordView: View {
    let title: String
    let message: String
    let trend: Trend?
    let infoButtonAction: () -> Void
    let containerWidth: CGFloat
    var estimateTitleAndMessageSizes: Bool = true
    var adaptiveLayout: Bool = false

    @State private var titleTargetWidth: CGFloat = .zero
    @State private var messageTargetWidth: CGFloat = .zero

    private var minimumWidth: CGFloat {
        let widthToCompare = max(titleTargetWidth, messageTargetWidth)
        return widthToCompare >= containerWidth ? containerWidth : widthToCompare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleView

            messageView
        }
        .if(adaptiveLayout) { view in
            view
                .frame(minWidth: minimumWidth, maxWidth: containerWidth, alignment: .leading)
                .overlay {
                    titleView
                        .opacity(0.0)
                        .fixedSize()
                        .readGeometry(\.size.width, bindTo: $titleTargetWidth)
                }
                .if(estimateTitleAndMessageSizes) { view in
                    view.overlay {
                        messageView
                            .opacity(0.0)
                            .fixedSize()
                            .readGeometry(\.size.width, bindTo: $messageTargetWidth)
                    }
                }
        }
    }

    private var titleView: some View {
        Button(action: infoButtonAction, label: {
            HStack(spacing: 4) {
                Text(title)
                    .lineLimit(1)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Assets.infoCircle16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
        })
    }

    private var messageView: some View {
        HStack(spacing: 4) {
            Text(message)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

            switch trend {
            case .positive:
                Assets.quotePositive.image
            case .negative:
                Assets.quoteNegative.image
            case .none:
                EmptyView()
            }
        }
    }
}

extension TokenMarketsDetailsStatisticsRecordView {
    enum Trend {
        case positive
        case negative
    }
}

#Preview {
    VStack {
        TokenMarketsDetailsStatisticsRecordView(
            title: "Experienced buyers",
            message: "+44",
            trend: .positive,
            infoButtonAction: {},
            containerWidth: 300
        )

        TokenMarketsDetailsStatisticsRecordView(
            title: "Market capitalization",
            message: "-$26,444,579,982,572,657.00",
            trend: .negative,
            infoButtonAction: {},
            containerWidth: 300
        )

        TokenMarketsDetailsStatisticsRecordView(
            title: "Experienced buyers",
            message: "44",
            trend: nil,
            infoButtonAction: {},
            containerWidth: 300
        )
    }
}
