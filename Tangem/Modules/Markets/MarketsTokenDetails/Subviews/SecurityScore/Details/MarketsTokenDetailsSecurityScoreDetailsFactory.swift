//
//  MarketsTokenDetailsSecurityScoreDetailsFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsSecurityScoreDetailsFactory {
    func makeViewModel(
        with providers: [MarketsTokenDetailsSecurityScore.Provider],
        routable: MarketsTokenDetailsSecurityScoreDetailsRoutable?
    ) -> MarketsTokenDetailsSecurityScoreDetailsViewModel {
        let iconBuilder = IconURLBuilder()
        let helper = MarketsTokenDetailsSecurityScoreRatingHelper()

        return MarketsTokenDetailsSecurityScoreDetailsViewModel(
            providers: providers.map { provider in
                let iconURL = iconBuilder.securityScoreProviderIconURL(providerId: provider.id, size: .small)
                let ratingBullets = helper.makeRatingBullets(forSecurityScoreValue: provider.securityScore)
                let securityScore = helper.makeSecurityScore(forSecurityScoreValue: provider.securityScore)
                let ratingViewData = MarketsTokenDetailsSecurityScoreRatingViewData(
                    ratingBullets: ratingBullets,
                    securityScore: securityScore
                )

                return .init(
                    name: provider.name,
                    iconURL: iconURL,
                    ratingViewData: ratingViewData,
                    auditDate: provider.auditDate?.formatted(date: .numeric, time: .omitted),
                    auditURL: provider.auditURL
                )
            },
            routable: routable
        )
    }
}
