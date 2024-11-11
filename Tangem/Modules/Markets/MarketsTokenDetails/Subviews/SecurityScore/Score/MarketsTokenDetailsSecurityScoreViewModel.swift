//
//  MarketsTokenDetailsSecurityScoreViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenDetailsSecurityScoreViewModel {
    var title: String { "Security score" } // TODO: Andrey Fedorov - Localization

    var subtitle: String { "Based on \(providerData.count) ratings" } // TODO: Andrey Fedorov - Localization

    private(set) lazy var securityScore: String = MarketsTokenDetailsSecurityScoreRatingHelper()
        .makeSecurityScore(forSecurityScoreValue: securityScoreValue)

    private(set) lazy var ratingBullets: [MarketsTokenDetailsSecurityScoreRatingViewData.RatingBullet] = MarketsTokenDetailsSecurityScoreRatingHelper()
        .makeRatingBullets(forSecurityScoreValue: securityScoreValue)

    private let providerData: [MarketsTokenDetailsSecurityData.ProviderData] // TODO: Andrey Fedorov - Replace with a dedicated domain model and rename
    private let securityScoreValue: Double

    private weak var routable: MarketsTokenDetailsSecurityScoreRoutable?

    init(
        providerData: [MarketsTokenDetailsSecurityData.ProviderData],
        securityScoreValue: Double,
        routable: MarketsTokenDetailsSecurityScoreRoutable?
    ) {
        self.providerData = providerData
        self.securityScoreValue = securityScoreValue
        self.routable = routable
    }

    func onInfoButtonTap() {
        routable?.openSecurityScoreDetails(with: providerData)
    }
}
