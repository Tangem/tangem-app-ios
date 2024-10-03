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
        case .risky: return Localization.marketsTokenDetailsExchangeTrustScoreRisky
        case .caution: return Localization.marketsTokenDetailsExchangeTrustScoreCaution
        case .trusted: return Localization.marketsTokenDetailsExchangeTrustScoreTrusted
        }
    }

    var textColor: Color {
        switch self {
        case .risky: return Colors.Text.warning
        case .caution: return Colors.Text.attention
        case .trusted: return Colors.Text.accent
        }
    }

    var backgroundColor: Color {
        switch self {
        case .risky: return Colors.Icon.warning.opacity(0.1)
        case .caution: return Colors.Icon.attention.opacity(0.1)
        case .trusted: return Colors.Icon.accent.opacity(0.1)
        }
    }
}
