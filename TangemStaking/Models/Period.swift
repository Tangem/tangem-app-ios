//
//  Period.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum Period: Hashable {
    case days(_ days: Int)

    public var isZero: Bool {
        switch self {
        case .days(let days):
            return days == 0
        }
    }
}
