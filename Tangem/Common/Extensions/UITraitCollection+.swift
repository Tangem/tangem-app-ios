//
//  UITraitCollection+.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

extension UITraitCollection {
    static var isDarkMode: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
    }
}
