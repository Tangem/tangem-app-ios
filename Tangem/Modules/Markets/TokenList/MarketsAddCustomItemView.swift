//
//  MarketsAddCustomItemView.swift
//  Tangem
//
//  Created by skibinalexander on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsAddCustomItemView: View {
    let didTapAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CircleIconView(image: Assets.plusMini.image)

            Text(Localization.addCustomTokenTitle)
                .lineLimit(1)
                .layoutPriority(-1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .animation(nil) // Disable animations on scroll reuse
        .onTapGesture {
            didTapAction()
        }
    }
}

private struct CircleIconView: View {
    let image: Image
    var imageSize: CGSize = .init(width: 16, height: 16)
    var circleSize: CGSize = .init(bothDimensions: 36)

    var body: some View {
        image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
            .frame(width: imageSize.width, height: imageSize.height)
            .padding(10)
            .background(Colors.Button.secondary)
            .cornerRadiusContinuous(18)
    }

    @ViewBuilder
    private var background: some View {
        Circle()
            .frame(width: circleSize.width, height: circleSize.height)
            .foregroundColor(Colors.Button.secondary)
    }
}
