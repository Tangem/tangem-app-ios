//
//  MarketsTokenDetailsExchangeItemView.swift
//  Tangem
//
//  Created by Andrew Son on 03.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsExchangeItemView: View {
    let info: MarketsTokenDetailsExchangeItemInfo

    var body: some View {
        HStack(spacing: 12) {
            icon

            content
        }
        .padding(14)
    }

    @ViewBuilder
    private var icon: some View {
        if let iconURL = info.iconURL {
            IconView(
                url: iconURL,
                size: .init(bothDimensions: 36),
                cornerRadius: 18
            )
        } else {
            SkeletonView()
                .frame(size: .init(bothDimensions: 36))
                .cornerRadiusContinuous(18)
        }
    }

    private var content: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(info.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(info.formattedVolume)")
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(info.exchangeType.title)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ExchangeTrustScoreView(trustScore: info.trustScore)
            }
        }
    }
}

private extension MarketsTokenDetailsExchangeItemView {
    struct ExchangeTrustScoreView: View {
        let trustScore: MarketsExchangeTrustScore

        var body: some View {
            Text(trustScore.title)
                .style(Fonts.Bold.caption2, color: trustScore.textColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(trustScore.backgroundColor)
                .cornerRadiusContinuous(4)
        }
    }
}

#Preview {
    MarketsTokenDetailsExchangeItemView(info: .init(
        id: "changenow",
        name: "ChangeNow",
        trustScore: .trusted,
        exchangeType: .cex,
        iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW1024.png"),
        formattedVolume: "$40B"
    ))
}
