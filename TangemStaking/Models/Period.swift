//
//  Period.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum Period {
    case days(_ days: Int)

    // TODO: To UI layer
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.day]
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        }
    }
}
