//
//  TokenMarketsDetailsLinksView.swift
//  Tangem
//
//  Created by Andrew Son on 04/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsLinkSection: Identifiable {
    let section: Section
    let chips: [MarketsTokenDetailsLinkChipsData]

    var id: String { section.rawValue }
}

extension TokenMarketsDetailsLinkSection {
    enum Section: String {
        case officialLinks
        case social
        case repository
        case blockchainSite

        var title: String {
            switch self {
            case .officialLinks: return Localization.marketsTokenDetailsOfficialLinks
            case .social: return Localization.marketsTokenDetailsSocial
            case .repository: return Localization.marketsTokenDetailsRepository
            case .blockchainSite: return Localization.marketsTokenDetailsBlockchainSite
            }
        }
    }
}

struct TokenMarketsDetailsLinksView: View {
    let sections: [TokenMarketsDetailsLinkSection]

    private let chipsSettings = MarketsTokenDetailsLinkChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Field.focused,
        font: Fonts.Bold.caption1
    )

    @State private var width: CGFloat = 0

    var body: some View {
        if sections.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                HStack {
                    Text("Links")
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        .padding(.top, 2)

                    Spacer()
                }
                .padding(.horizontal, Constants.horizontalPadding)

                ForEach(sections) { sectionInfo in
                    if sectionInfo.chips.isEmpty {
                        EmptyView()
                    } else {
                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            Group {
                                Text(sectionInfo.section.title)
                                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                                MarketsTokenDetailsChipsContainer(
                                    chipsData: sectionInfo.chips,
                                    parentWidth: width - Constants.horizontalPadding * 2
                                )
                            }
                            .padding(.horizontal, Constants.horizontalPadding)

                            if sectionInfo.id != sections.last?.id {
                                Separator(color: Colors.Stroke.primary, axis: .horizontal)
                                    .padding(.leading, Constants.horizontalPadding)
                            }
                        }
                    }
                }
                .readGeometry(\.size.width, bindTo: $width)
            }
            .defaultRoundedBackground(with: Colors.Background.action, horizontalPadding: 0)
        }
    }
}

extension TokenMarketsDetailsLinksView {
    enum Constants {
        static let horizontalPadding: CGFloat = 14
        static let verticalSpacing: CGFloat = 12
    }
}

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
                MarketsTokenDetailsLinkChipsView(
                    text: data.text,
                    icon: data.icon,
                    style: chipsSettings,
                    action: data.action
                )
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > parentWidth {
                        width = 0
                        height -= dimension.height + verticalItemsSpacing
                    }
                    let result = width
                    if data.id == chipsData.last?.id {
                        width = 0
                    } else {
                        width -= dimension.width + horizontalItemsSpacing
                    }
                    return result
                }
                .alignmentGuide(.top) { dimension in
                    let result = height
                    if data.id == chipsData.last?.id {
                        height = 0
                    }
                    return result
                }
            }
        })
    }
}

struct MarketsTokenDetailsLinkChipsData: Identifiable {
    let text: String
    let icon: MarketsTokenDetailsLinkChipsView.Icon?
    let link: String
    let action: () -> Void

    var id: String {
        link
    }
}

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
    return TokenMarketsDetailsLinksView(sections: [
        .init(
            section: .officialLinks,
            chips: [
                .init(
                    text: "Website",
                    icon: .leading(Assets.arrowRightUp),
                    link: "3243109",
                    action: {}
                ),
                .init(
                    text: "Whitepaper",
                    icon: .leading(Assets.whitepaper),
                    link: "s2dfopefew",
                    action: {}
                ),
                .init(
                    text: "Forum",
                    icon: .leading(Assets.arrowRightUp),
                    link: "jfdksofnv,cnxbkr   ",
                    action: {}
                ),
            ]
        ),
    ])
    .padding(.horizontal, 16)
}
