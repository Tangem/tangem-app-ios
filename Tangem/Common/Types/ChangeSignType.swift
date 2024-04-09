//
//  ChangeSignType.swift
//  Tangem
//
//  Created by Andrey Chukavin on 12.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

enum ChangeSignType: Int, Hashable {
    case positive
    case neutral
    case negative

    init(from value: Decimal) {
        if value == .zero {
            self = .neutral
        } else if value > 0 {
            self = .positive
        } else {
            self = .negative
        }
    }

    var imageType: ImageType? {
        switch self {
        case .positive:
            return Assets.quotePositive
        case .neutral:
            return Assets.quoteNeutral
        case .negative:
            return Assets.quoteNegative
        }
    }

    var textColor: Color {
        switch self {
        case .positive:
            return Colors.Text.accent
        case .neutral:
            return Colors.Text.tertiary
        case .negative:
            return Colors.Text.warning
        }
    }
}
