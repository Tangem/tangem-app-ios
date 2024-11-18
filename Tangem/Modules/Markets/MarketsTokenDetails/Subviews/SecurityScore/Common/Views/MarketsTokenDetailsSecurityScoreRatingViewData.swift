//
//  MarketsTokenDetailsSecurityScoreRatingViewData.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsSecurityScoreRatingViewData {
    struct RatingBullet {
        let value: Double
    }

    let ratingBullets: [RatingBullet]
    let securityScore: String
}
