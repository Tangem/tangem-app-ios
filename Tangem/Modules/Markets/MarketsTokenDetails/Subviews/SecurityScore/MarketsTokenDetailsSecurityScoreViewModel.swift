//
//  MarketsTokenDetailsSecurityScoreViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenDetailsSecurityScoreViewModel {
    struct RatingBullet {
        let value: Double
    }

    var title: String { "Security score" } // TODO: Andrey Fedorov - Localization

    var subtitle: String { "Based on \(providerData.count) ratings" } // TODO: Andrey Fedorov - Localization

    private(set) lazy var securityScore: String = securityScoreValue.formatted(
        .number
            .grouping(.never)
            .decimalSeparator(strategy: .always)
            .precision(.fractionLength(1 ... 1))
    )

    private(set) lazy var ratingBullets: [RatingBullet] = {
        let filletBulletsCount = Int(securityScoreValue)
        let intermediateBulletValue = securityScoreValue - Double(filletBulletsCount) // TODO: Andrey Fedorov - Rounding?
        let emptyBulletsCount = max(5 - filletBulletsCount - 1, 0)

        return [RatingBullet](repeating: RatingBullet(value: 1.0), count: filletBulletsCount)
            + [RatingBullet(value: intermediateBulletValue)]
            + [RatingBullet](repeating: RatingBullet(value: 0.0), count: emptyBulletsCount)
    }()

    private let providerData: [MarketsTokenDetailsSecurityData.ProviderData] // TODO: Andrey Fedorov - Replace with a dedicated domain model
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
        // TODO: Andrey Fedorov - Add actual implementation
    }
}
