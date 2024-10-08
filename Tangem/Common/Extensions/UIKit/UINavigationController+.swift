//
//  UINavigationController+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC.runtime

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

    /// Unlike `UINavigationController.setNavigationBarHidden(_:animated:)` from UIKit or `navigationBarHidden(_:)`
    /// from SwiftUI, this approach will hide the navigation bar without breaking the swipe-to-pop gesture.
    func setNavigationBarAlwaysHidden() {
        let classNamePrefix = "_TangemAlwaysHidden"

        guard let navigationBarClass = object_getClass(navigationBar) else {
            assertionFailure("Unable to get class for instance \(navigationBar)")
            return
        }

        let className = String(cString: class_getName(navigationBarClass))

        guard !className.hasSuffix(classNamePrefix) else {
            // Navigation bar already subclassed, nothing to do here
            return
        }

        let subclassName = className.appending(classNamePrefix)

        if let subclass = NSClassFromString(subclassName) ?? makeAlwaysHiddenNavigationBarSubclass(
            subclassName: subclassName,
            navigationBarClass: navigationBarClass
        ) {
            object_setClass(navigationBar, subclass)
        } else {
            assertionFailure("Unable to find existing or create new class \(subclassName)")
        }

        // Hides navigation bar on the next layout cycle
        navigationBar.setNeedsLayout()
    }
}

// MARK: - Private implementation

private extension UINavigationController {
    func makeAlwaysHiddenNavigationBarSubclass(subclassName: String, navigationBarClass: AnyClass) -> AnyClass? {
        guard
            let subclassNameUTF8 = (subclassName as NSString).utf8String,
            let subclass = objc_allocateClassPair(navigationBarClass, subclassNameUTF8, 0)
        else {
            assertionFailure("Unable to allocate class pair for subclass \(subclassName) and parent class \(navigationBarClass)")
            return nil
        }

        let selector = #selector(UINavigationBar.layoutSubviews)

        if let method = class_getInstanceMethod(UINavigationBar.self, selector) {
            let methodHook: @convention(block) (_ instance: UINavigationBar) -> Void = { instance in
                // Default implementation does nothing, no need to call super
                instance.isHidden = true
            }
            let implementation = imp_implementationWithBlock(methodHook)
            let typeEncoding = method_getTypeEncoding(method)
            class_addMethod(subclass, selector, implementation, typeEncoding)
        } else {
            assertionFailure("Unable to find method for selector \(selector)")
        }

        objc_registerClassPair(subclass)

        return subclass
    }
}
