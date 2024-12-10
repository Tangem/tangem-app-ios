//
//  OverlayContentContainerAppLifecycleHelper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIApplication
import Combine
import CombineExt

protocol OverlayContentContainerAppLifecycleHelperDelegate: AnyObject {
    func currentProgress(for appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) -> CGFloat
    func appLifecycleHelperDidTriggerExpand(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper)
    func appLifecycleHelperDidTriggerCollapse(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper)
}

final class OverlayContentContainerAppLifecycleHelper {
    weak var delegate: OverlayContentContainerAppLifecycleHelperDelegate?

    private var notificationCenter: NotificationCenter { .default }
    private var notificationSubscription: AnyCancellable?

    func observeLifecycleIfNeeded() {
        guard notificationSubscription == nil else {
            return
        }

        notificationSubscription = notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .withWeakCaptureOf(self)
            .sink { helper, _ in
                helper.onDidBecomeActive()
            }
    }

    private func onDidBecomeActive() {
        guard let delegate else {
            return
        }

        // Prevents the overlay from getting stuck in an intermediate state if the drag gesture
        // is interrupted in the middle by sending the app to the background
        if delegate.currentProgress(for: self) >= 0.5 {
            delegate.appLifecycleHelperDidTriggerExpand(self)
        } else {
            delegate.appLifecycleHelperDidTriggerCollapse(self)
        }
    }
}
