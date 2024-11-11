//
//  MarketsTokenDetailsSecurityScoreDetailsViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenDetailsSecurityScoreDetailsViewModel: ObservableObject, Identifiable {
    struct SecurityScoreProviderData: Identifiable {
        var securityScore: String {
            MarketsTokenDetailsSecurityScoreRatingHelper().makeSecurityScore(forSecurityScoreValue: securityScoreValue)
        }

//        private(set) lazy var securityScore: String = MarketsTokenDetailsSecurityScoreRatingHelper()
//            .makeSecurityScore(forSecurityScoreValue: securityScoreValue)

        var ratingBullets: [MarketsTokenDetailsSecurityScoreRatingViewData.RatingBullet] {
            MarketsTokenDetailsSecurityScoreRatingHelper().makeRatingBullets(forSecurityScoreValue: securityScoreValue)
        }

//        private(set) lazy var ratingBullets: [MarketsTokenDetailsSecurityScoreRatingViewData.RatingBullet] = MarketsTokenDetailsSecurityScoreRatingHelper()
//            .makeRatingBullets(forSecurityScoreValue: securityScoreValue)

        let id = UUID()
        let name: String
        let auditDate: String?
        let iconURL: URL
        let providerURL: URL?
        let securityScoreValue: Double

        var linkTitle: String? {
            if #available(iOS 16.0, *) {
                providerURL?.host()
            } else {
                providerURL?.host
            }
        }
    }

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
            let providerURL = provider.providerURL
        else {
            return
        }

        routable?.openSecurityAudit(at: providerURL)
    }
}
