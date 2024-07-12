//
//  TokenMarketsDetailsLinksView.swift
//  Tangem
//
//  Created by Andrew Son on 04/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsLinkSection: Identifiable {
    let title: String
    let chips: [ChipsData]

    var id: String { title }
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
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsTokenDetailsLinks)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.top, 2)

            
        }
        .defaultRoundedBackground()
    }
}

struct ChipsData: Identifiable {
    let text: String
    let icon: ChipsView.Icon
    let style: ChipsView.StyleSettings
    let link: String
    let action: () -> Void

    var id: String {
        link
    }
}

struct ChipsView: View {
    let text: String
    let icon: Icon
    let style: StyleSettings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                switch icon {
                case .leading(let image):
                    stylizedIcon(icon: image)

                    textView
                case .trailing(let image):
                    textView

                    stylizedIcon(icon: image)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
    }

    private var textView: some View {
        Text(text)
            .style(style.font, color: style.textColor)
    }

    private func stylizedIcon(icon: Image) -> some View {
        icon
            .renderingMode(.template)
            .foregroundStyle(style.iconColor)
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
    let chipsSettings = ChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Field.focused,
        font: Fonts.Bold.caption1
    )

    return TokenMarketsDetailsLinksView(sections: [
        .init(
            title: "Official Links",
            chips: [
                .init(
                    text: "Website",
                    icon: .leading(Assets.arrowRightUp16.image),
                    style: chipsSettings,
                    link: "3243109",
                    action: {}
                ),
                .init(
                    text: "Whitepaper",
                    icon: .leading(Assets.whitepaper16.image),
                    style: chipsSettings,
                    link: "s2dfopefew",
                    action: {}
                ),
                .init(
                    text: "Forum",
                    icon: .leading(Assets.arrowRightUp16.image),
                    style: chipsSettings,
                    link: "jfdksofnv,cnxbkr   ",
                    action: {}
                ),
            ]
        ),
    ])
}
