//
//  MarketsTokenDetailsLinkModels.swift
//  Tangem
//
//  Created by Andrew Son on 12/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsLinkSection: Identifiable {
    let section: Section
    let chips: [MarketsTokenDetailsLinkChipsData]

    var id: String { section.rawValue }
}

extension MarketsTokenDetailsLinkSection {
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

struct MarketsTokenDetailsLinkChipsData: Identifiable {
    let text: String
    let icon: MarketsTokenDetailsLinkChipsView.Icon?
    let link: String
    let action: () -> Void

    var id: String {
        link + text
    }
}
