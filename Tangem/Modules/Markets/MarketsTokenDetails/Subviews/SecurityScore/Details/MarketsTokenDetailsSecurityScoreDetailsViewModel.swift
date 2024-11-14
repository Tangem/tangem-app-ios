//
//  MarketsTokenDetailsSecurityScoreDetailsViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class MarketsTokenDetailsSecurityScoreDetailsViewModel: Identifiable {
    var title: String { Localization.marketsTokenDetailsSecurityScore }
    var subtitle: String { Localization.marketsTokenDetailsSecurityScoreDescription }
    let providers: [SecurityScoreProviderData]

    private weak var routable: MarketsTokenDetailsSecurityScoreDetailsRoutable?

    init(
        providers: [MarketsTokenDetailsSecurityScoreDetailsViewModel.SecurityScoreProviderData],
        routable: MarketsTokenDetailsSecurityScoreDetailsRoutable?
    ) {
        self.providers = providers
        self.routable = routable
    }

    func onProviderLinkTap(with identifier: SecurityScoreProviderData.ID) {
        guard
            let provider = providers.first(where: { $0.id == identifier }),
            let auditURL = provider.auditURL
        else {
            return
        }

        routable?.openSecurityAudit(at: auditURL)
    }
}

// MARK: - Auxiliary types

extension MarketsTokenDetailsSecurityScoreDetailsViewModel {
    struct SecurityScoreProviderData: Identifiable {
        let id = UUID()
        let name: String
        let iconURL: URL
        let ratingViewData: MarketsTokenDetailsSecurityScoreRatingViewData
        let auditDate: String?
        let auditURL: URL?
        var auditURLTitle: String? { auditURL?.topLevelDomain }
    }
}
