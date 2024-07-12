//
//  TokenMarketsDetailsLinksView.swift
//  Tangem
//
//  Created by Andrew Son on 04/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

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
                    Text(Localization.marketsTokenDetailsLinks)
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
