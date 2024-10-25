//
//  MarketsTokenDetailsLinksView.swift
//  Tangem
//
//  Created by Andrew Son on 04/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsLinksView: View {
    let viewWidth: CGFloat
    let sections: [MarketsTokenDetailsLinkSection]

    private let chipsSettings = MarketsTokenDetailsLinkChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Field.focused,
        font: Fonts.Bold.caption1
    )

    var body: some View {
        if sections.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: .zero) {
                BlockHeaderTitleView(title: Localization.marketsTokenDetailsLinks)
                    .padding(.horizontal, Constants.horizontalPadding)

                VStack(alignment: .leading) {
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
                                        parentWidth: viewWidth - Constants.horizontalPadding * 2
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
                }
                .padding(.vertical, Constants.verticalSpacing)
            }
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero, horizontalPadding: .zero)
        }
    }
}

extension MarketsTokenDetailsLinksView {
    enum Constants {
        static let horizontalPadding: CGFloat = 14
        static let verticalSpacing: CGFloat = 12
    }
}

#Preview {
    return MarketsTokenDetailsLinksView(
        viewWidth: 400,
        sections: [
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
        ]
    )
    .padding(.horizontal, 16)
}
