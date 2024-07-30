//
//  MarketsListStateUpdater.swift
//  Tangem
//
//  Created by Andrew Son on 30/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsListStateUpdater: AnyObject {
    func invalidateCells(in range: ClosedRange<Int>)
    func setupUpdates(for range: ClosedRange<Int>)
}
