//
//  MarketsTokenDetailsSecurityScoreViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenDetailsSecurityScoreViewModel {
    var title: String { Localization.marketsTokenDetailsSecurityScore }
    var subtitle: String { Localization.marketsTokenDetailsBasedOnRatings(providers.count) }

    private(set) lazy var ratingViewData: MarketsTokenDetailsSecurityScoreRatingViewData = {
        let helper = MarketsTokenDetailsSecurityScoreRatingHelper()
        let ratingBullets = helper.makeRatingBullets(forSecurityScoreValue: securityScoreValue)
        let securityScore = helper.makeSecurityScore(forSecurityScoreValue: securityScoreValue)

        return MarketsTokenDetailsSecurityScoreRatingViewData(ratingBullets: ratingBullets, securityScore: securityScore)
    }()

    private let providers: [MarketsTokenDetailsSecurityScore.Provider]
    private let securityScoreValue: Double

    private weak var routable: MarketsTokenDetailsSecurityScoreRoutable?

    init(
        securityScoreValue: Double,
        providers: [MarketsTokenDetailsSecurityScore.Provider],
        routable: MarketsTokenDetailsSecurityScoreRoutable?
    ) {
        self.securityScoreValue = securityScoreValue
        self.providers = providers
        self.routable = routable
    }

    func onInfoButtonTap() {
        routable?.openSecurityScoreDetails(with: providers)
    }
}
