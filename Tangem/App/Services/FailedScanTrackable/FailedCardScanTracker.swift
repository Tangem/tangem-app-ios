//
//  ScanCardObserver.swift
//  Tangem
//
//  Created by Andrew Son on 20/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FailedCardScanTracker: FailedScanTrackable {
    var shouldDisplayAlert: Bool {
        numberOfFailedAttempts >= 2
    }

    private(set) var numberOfFailedAttempts: Int = 0

    func resetCounter() {
        numberOfFailedAttempts = 0
    }

    func recordFailure() {
        numberOfFailedAttempts += 1
    }
}
