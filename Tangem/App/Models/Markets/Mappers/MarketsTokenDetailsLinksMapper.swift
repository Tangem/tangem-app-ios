//
//  MarketsTokenDetailsLinksMapper.swift
//  Tangem
//
//  Created by Andrew Son on 12/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsLinksMapper {
    private let defaultIcon = Assets.arrowRightUp

    let openLinkAction: (String) -> Void

    func mapToSections(_ links: MarketsTokenDetailsLinks) -> [TokenMarketsDetailsLinkSection] {
        return [
            .init(section: .officialLinks, chips: mapLinksToChips(links.officialLinks)),
            .init(section: .social, chips: mapLinksToChips(links.social)),
            .init(section: .repository, chips: mapLinksToChips(links.repository)),
            .init(section: .blockchainSite, chips: mapLinksToChips(links.blockchainSite)),
        ]
    }

    private func mapLinksToChips(_ links: [MarketsTokenDetailsLinks.LinkInfo]) -> [MarketsTokenDetailsLinkChipsData] {
        return links.map { mapLinkToChips($0) }
    }

    private func mapLinkToChips(_ linkInfo: MarketsTokenDetailsLinks.LinkInfo) -> MarketsTokenDetailsLinkChipsData {
        var icon: ImageType = defaultIcon
        if let id = linkInfo.id {
            icon = .init(name: id)
        }

        var title = linkInfo.title
        if let url = URL(string: linkInfo.title), let hostTitle = url.host {
            title = hostTitle
        }
        return .init(
            text: title,
            icon: .leading(icon),
            link: linkInfo.link,
            action: {
                openLinkAction(linkInfo.link)
            }
        )
    }
}
