//
//  TokenMarketsDetailsLinksView.swift
//  Tangem
//
//  Created by Andrew Son on 04/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsLinkSection {
    let title: String
    let chips: [ChipsData]
}

struct TokenMarketsDetailsLinksView: View {
    let sections: [TokenMarketsDetailsLinkSection]

    private let chipsSettings = ChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Field.focused,
        font: Fonts.Bold.caption1
    )

    var body: some View {
        VStack(alignment: .leading) {
            Text(Localization.marketsTokenDetailsLinks)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        }
        .defaultRoundedBackground()
    }
}

struct ChipsData {
    let text: String
    let icon: ChipsView.Icon
    let style: ChipsView.StyleSettings
}

struct ChipsView: View {
    let text: String
    let icon: Icon
    let style: StyleSettings

    var body: some View {
        HStack(spacing: 4) {
            switch icon {
            case .leading(let image):
                image
                    .renderingMode(.template)
                    .foregroundStyle(style.iconColor)

                textView
            case .trailing(let image):
                textView

                image
                    .renderingMode(.template)
                    .foregroundStyle(style.iconColor)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)

    }

    private var textView: some View {
        Text(text)
            .style(style.font, color: style.textColor)
    }
}

extension ChipsView {
    enum Icon {
        case leading(Image)
        case trailing(Image)
    }

    struct StyleSettings {
        let iconColor: Color
        let textColor: Color
        let backgroundColor: Color
        let font: Font
    }
}

#Preview {
    TokenMarketsDetailsLinksView(sections: [
        .init(title: "Official links",
              chips: <#T##[ChipsData]#>)
    ])
}
