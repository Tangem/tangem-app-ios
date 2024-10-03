//
//  Analytics+DebugEvent.swift
//  Tangem
//
//  Created by Andrew Son on 27/10/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AnalyticsDebugEvent {
    var title: String { get }
    var analyticsParams: [String: Any] { get }
}
