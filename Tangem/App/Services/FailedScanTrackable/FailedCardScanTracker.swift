//
//  ScanCardObserver.swift
//  Tangem
//
//  Created by Andrew Son on 20/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FailedCardScanTracker: EmailDataCollector, FailedScanTrackable {
    var logData: Data? {
        ("----------\n" + DeviceInfoProvider.info()).data(using: .utf8)
    }

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
