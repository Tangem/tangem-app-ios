//
//  CALayer+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) {
        cornerRadius = radius
        maskedCorners = corners.toCACornerMask()
        masksToBounds = true
    }
}
