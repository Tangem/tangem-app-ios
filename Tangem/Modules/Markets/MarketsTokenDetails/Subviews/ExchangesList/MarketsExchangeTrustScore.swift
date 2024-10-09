//
//  MarketsExchangeTrustScore.swift
//  Tangem
//
//  Created by Andrew Son on 03.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

enum MarketsExchangeTrustScore: Int, Decodable {
    case risky = 0
    case caution = 4
    case trusted = 8

    init(rawValue: Int?) {
        switch rawValue {
        case .none, .some(0 ... 3):
            self = .risky
        case .some(4 ... 7):
            self = .caution
        case .some(8...):
            self = .trusted
        default:
            self = .risky
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let scoreInt = try container.decode(Int.self)
        self = MarketsExchangeTrustScore(rawValue: scoreInt)
    }

    var title: String {
        switch self {
        case .risky: Localization.marketsTokenDetailsExchangeTrustScoreRisky
        case .caution: Localization.marketsTokenDetailsExchangeTrustScoreCaution
        case .trusted: Localization.marketsTokenDetailsExchangeTrustScoreTrusted
        }
    }

    var textColor: Color {
        switch self {
        case .risky: Colors.Text.warning
        case .caution: Colors.Text.attention
        case .trusted: Colors.Text.accent
        }
    }

    var backgroundColor: Color {
        switch self {
        case .risky: Colors.Icon.warning.opacity(0.1)
        case .caution: Colors.Icon.attention.opacity(0.1)
        case .trusted: Colors.Icon.accent.opacity(0.1)
        }
    }
}
