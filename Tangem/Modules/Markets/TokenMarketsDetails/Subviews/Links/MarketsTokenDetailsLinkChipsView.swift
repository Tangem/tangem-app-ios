//
//  MarketsTokenDetailsLinkChipsView.swift
//  Tangem
//
//  Created by Andrew Son on 12/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsLinkChipsView: View {
    let text: String
    let icon: Icon?
    let style: StyleSettings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                switch icon {
                case .leading(let imageType):
                    stylizedIcon(icon: imageType)

                    textView
                case .trailing(let imageType):
                    textView

                    stylizedIcon(icon: imageType)
                case .none:
                    textView
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(style.backgroundColor)
            .cornerRadiusContinuous(14)
        }
    }

    private var textView: some View {
        Text(text)
            .style(style.font, color: style.textColor)
    }

    private func stylizedIcon(icon: ImageType) -> some View {
        icon.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(style.iconColor)
            .frame(size: .init(bothDimensions: 16))
    }
}

extension MarketsTokenDetailsLinkChipsView {
    enum Icon {
        case leading(ImageType)
        case trailing(ImageType)
    }

    struct StyleSettings {
        let iconColor: Color
        let textColor: Color
        let backgroundColor: Color
        let font: Font
    }
}

#Preview {
    let chipsSettings = MarketsTokenDetailsLinkChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Background.tertiary,
        font: Fonts.Bold.caption1
    )

    return VStack {
        MarketsTokenDetailsLinkChipsView(
            text: "Whitepaper",
            icon: .leading(Assets.whitepaper),
            style: chipsSettings,
            action: {}
        )

        MarketsTokenDetailsLinkChipsView(
            text: "Reddit",
            icon: .leading(Assets.SocialNetwork.discord),
            style: chipsSettings,
            action: {}
        )
    }
}
