//
//  StakingAnalytics.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAnalytics {
    static func log(_ event: String)
}
