//
//  MarketsTokenDetailsChipsContainer.swift
//  Tangem
//
//  Created by Andrew Son on 12/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsChipsContainer: View {
    let chipsData: [MarketsTokenDetailsLinkChipsData]
    let parentWidth: CGFloat
    var horizontalItemsSpacing: CGFloat = 12
    var verticalItemsSpacing: CGFloat = 12

    private let chipsSettings = MarketsTokenDetailsLinkChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Background.tertiary,
        font: Fonts.Bold.caption1
    )

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        ZStack(alignment: .topLeading, content: {
            ForEach(chipsData) { data in
                let isFirstItem = data.id == chipsData.first?.id
                let isLastItem = data.id == chipsData.last?.id
                MarketsTokenDetailsLinkChipsView(
                    text: data.text,
                    icon: data.icon,
                    style: chipsSettings,
                    action: data.action
                )
                .alignmentGuide(.leading) { dimension in
                    if isFirstItem {
                        width = 0
                    }
                    if abs(width - dimension.width) > parentWidth {
                        width = 0
                        height -= dimension.height + verticalItemsSpacing
                    }
                    let result = width
                    if isLastItem {
                        width = 0
                    } else {
                        width -= dimension.width + horizontalItemsSpacing
                    }
                    return result
                }
                .alignmentGuide(.top) { dimension in
                    if isFirstItem {
                        height = 0
                    }
                    let result = height
                    if isLastItem {
                        height = 0
                    }
                    return result
                }
            }

            // We need this view to fix items vertical alignment.
            // SwiftUI on iOS 18 not correctly align elements in ZStack, it moves items up O_o
            Color.clear
                .frame(width: 1)
        })
    }
}
