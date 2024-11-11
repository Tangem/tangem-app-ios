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

    // TODO: Andrey Fedorov - Localization
    var title: String {
        "Security score"
    }

    // TODO: Andrey Fedorov - Localization
    var subtitle: String {
        "Security score of a token is a metric that assesses the security level of a blockchain or token based on various factors and is compiled from the sources listed below."
    }

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
