//
//  UINavigationController+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    func setDelegateSafe(_ newDelegate: UINavigationControllerDelegate?) {
        if delegate === newDelegate {
            return
        }

        if delegate != nil {
            assertionFailure("Attempting to erase an internal SwiftUI delegate \(String(describing: delegate))")
        } else {
            delegate = newDelegate
        }
    }
}
