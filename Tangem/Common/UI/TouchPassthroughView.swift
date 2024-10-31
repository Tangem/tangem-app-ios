//
//  TouchPassthroughView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

protocol TouchPassthroughViewDelegate: AnyObject {
    func touchPassthroughView(
        _ passthroughView: TouchPassthroughView,
        shouldPassthroughTouchAt point: CGPoint,
        with event: UIEvent?
    ) -> Bool
}

/// Passthroughs all touches by default (if no delegate is set).
final class TouchPassthroughView: UIView {
    weak var delegate: TouchPassthroughViewDelegate?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let delegate else {
            return nil
        }

        if delegate.touchPassthroughView(self, shouldPassthroughTouchAt: point, with: event) {
            return nil
        }

        return super.hitTest(point, with: event)
    }
}
