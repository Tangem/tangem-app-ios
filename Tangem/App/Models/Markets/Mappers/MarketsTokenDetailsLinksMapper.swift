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

    let openLinkAction: (MarketsTokenDetailsLinks.LinkInfo) -> Void

    func mapToSections(_ links: MarketsTokenDetailsLinks?) -> [MarketsTokenDetailsLinkSection] {
        guard let links else {
            return []
        }

        var sections = [MarketsTokenDetailsLinkSection]()
        if let officialLinks = links.officialLinks, !officialLinks.isEmpty {
            sections.append(.init(section: .officialLinks, chips: mapLinksToChips(officialLinks)))
        }
        if let socialLinks = links.social, !socialLinks.isEmpty {
            sections.append(.init(section: .social, chips: mapLinksToChips(socialLinks)))
        }
        if let repositoryLinks = links.repository, !repositoryLinks.isEmpty {
            sections.append(.init(section: .repository, chips: mapLinksToChips(repositoryLinks)))
        }
        if let blockchainSiteLinks = links.blockchainSite, !blockchainSiteLinks.isEmpty {
            sections.append(.init(section: .blockchainSite, chips: mapLinksToChips(blockchainSiteLinks)))
        }

        return sections
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
                openLinkAction(linkInfo)
            }
        )
    }
}
