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

            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(info.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Spacer()

                    Text("\(info.formattedVolume)")
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(info.exchangeType.title)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Spacer()

                    ExchangeTrustScoreView(trustScore: info.trustScore)
                }
            }
        }
        .padding(14)
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
