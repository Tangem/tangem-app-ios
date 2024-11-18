//
//  MarketsTokenDetailsSecurityScoreRatingHelper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsSecurityScoreRatingHelper {
    typealias RatingBullet = MarketsTokenDetailsSecurityScoreRatingViewData.RatingBullet

    private let ratingBulletsCount: Int

    init(ratingBulletsCount: Int = 5) {
        self.ratingBulletsCount = ratingBulletsCount
    }

    func makeSecurityScore(forSecurityScoreValue securityScoreValue: Double) -> String {
        return securityScoreValue.formatted(
            .number
                .grouping(.never)
                .decimalSeparator(strategy: .always)
                .precision(.fractionLength(1 ... 1))
        )
    }

    func makeRatingBullets(forSecurityScoreValue securityScoreValue: Double) -> [RatingBullet] {
        let filledBulletsCount = Int(securityScoreValue)
        let intermediateBulletValue = securityScoreValue - Double(filledBulletsCount)
        let emptyBulletsCount = max(ratingBulletsCount - filledBulletsCount - 1, 0) // `-1` here due to an intermediate rating bullet
        let ratingBullets = [RatingBullet](repeating: .init(value: 1.0), count: filledBulletsCount)
            + [RatingBullet(value: intermediateBulletValue)]
            + [RatingBullet](repeating: .init(value: 0.0), count: emptyBulletsCount)

        return Array(ratingBullets.prefix(ratingBulletsCount))
    }
}
