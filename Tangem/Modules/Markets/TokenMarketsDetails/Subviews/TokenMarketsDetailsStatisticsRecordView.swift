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
    let infoButtonAction: () -> Void
    let containerWidth: CGFloat

    @State private var titleTargetWidth: CGFloat = .zero
    @State private var messageTargetWidth: CGFloat = .zero

    private var minimumWidth: CGFloat {
        let widthToCompare = max(titleTargetWidth, messageTargetWidth)
        return widthToCompare >= containerWidth ? containerWidth : widthToCompare
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleView

            messageView
        }
        .frame(minWidth: minimumWidth, maxWidth: containerWidth, alignment: .leading)
        .overlay {
            titleView
                .opacity(0.0)
                .fixedSize()
                .readGeometry(\.size.width, bindTo: $titleTargetWidth)
        }
        .overlay {
            messageView
                .opacity(0.0)
                .fixedSize()
                .readGeometry(\.size.width, bindTo: $messageTargetWidth)
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
        Text(message)
            .lineLimit(1)
            .fixedSize()
            .style(Fonts.Regular.callout, color: Colors.Text.primary1)
    }
}

#Preview {
    VStack {
        TokenMarketsDetailsStatisticsRecordView(
            title: "Experienced buyers",
            message: "+44",
            infoButtonAction: {},
            containerWidth: 300
        )

        TokenMarketsDetailsStatisticsRecordView(
            title: "Market capitalization",
            message: "+$26,444,579,982,572,657.00",
            infoButtonAction: {},
            containerWidth: 300
        )
    }
}
