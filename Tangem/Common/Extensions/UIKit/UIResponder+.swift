//
//  UIResponder+.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

extension UIResponder {
    private weak static var currentFirstResponder: UIResponder?

    public static var current: UIResponder? {
        UIResponder.currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
        return UIResponder.currentFirstResponder
    }

    @objc
    private func findFirstResponder(sender: AnyObject) {
        UIResponder.currentFirstResponder = self
    }
}
