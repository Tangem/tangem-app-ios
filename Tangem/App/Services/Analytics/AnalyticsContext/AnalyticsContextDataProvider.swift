//
//  AnalyticsContextDataProvider.swift
//  Tangem
//
//  Created by Andrew Son on 16/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AnalyticsContextDataProvider: AnyObject {
    func getAnalyticsContextData() -> AnalyticsContextData?
}
