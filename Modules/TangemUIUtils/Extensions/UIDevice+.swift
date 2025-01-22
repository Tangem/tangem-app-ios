//
//  UIDevice+.swift
//  TangemUIUtils
//
//  Created by Alexander Osokin on 12.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

public extension UIDevice {
    /// - Warning: Simple and naive, use with caution.
    var hasHomeScreenIndicator: Bool {
        return !UIApplication.safeAreaInsets.bottom.isZero
    }
}
