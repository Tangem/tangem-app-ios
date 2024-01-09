//
//  RootHostingController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

/// This root hosting controller allows external consumers to configure system status bar style.
///
/// On iOS 15 and below system configures status bar style by using values from the `preferredStatusBarStyle`
/// property, whereas on iOS 16 and above status bar style is controlled by the private child VC,
/// returned in the `childForStatusBarStyle` property.
/// This is the reason why we're overriding both of these properties in this subclass of `UIHostingController`.
final class RootHostingController<Content: View>: UIHostingController<Content> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // In cases when the selected status bar style is unchanged (equals `.default`) - we preserve default
        // system behavior and hand over control flow to the system by returning `super.preferredStatusBarStyle` here
        guard selectedStatusBarStyle != .default else {
            return super.preferredStatusBarStyle
        }

        return selectedStatusBarStyle
    }

    override var childForStatusBarStyle: UIViewController? {
        // In cases when the selected status bar style is unchanged (equals `.default`) - we preserve default
        // system behavior and hand over control flow to the system by returning `super.childForStatusBarStyle` here
        guard selectedStatusBarStyle != .default else {
            return super.childForStatusBarStyle
        }

        return nil
    }

    private var _selectedStatusBarStyle: UIStatusBarStyle = .default
}

// MARK: - StatusBarStyleConfigurator protocol conformance

extension RootHostingController: StatusBarStyleConfigurator {
    var selectedStatusBarStyle: UIStatusBarStyle {
        return _selectedStatusBarStyle
    }

    func setSelectedStatusBarStyle(_ statusBarStyle: UIStatusBarStyle, animated: Bool) {
        if statusBarStyle != _selectedStatusBarStyle {
            _selectedStatusBarStyle = statusBarStyle
            let animationDuration = animated ? 0.3 : 0.0
            UIView.animate(withDuration: animationDuration) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}
