//
//  UIApplication+.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        windows.first { $0.isKeyWindow }?.endEditing(true)
    }
}

extension UIApplication {
    static var keyWindow: UIWindow? {
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    static var activeScene: UIWindowScene? {
        return UIApplication
            .shared
            .connectedScenes.first { $0.activationState == .foregroundActive && $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }
    }

    static var topViewController: UIViewController? {
        return keyWindow?.topViewController
    }

    static func modalFromTop(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else { return }

        if top.isBeingDismissed || top.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                modalFromTop(vc)
            }
        } else {
            top.present(vc, animated: animated, completion: completion)
        }
    }

    static func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    // withTransaction not working with iOS16, UIView.performWithoutAnimations block not working
    static func performWithoutAnimations(_ block: () -> Void) {
        UIView.setAnimationsEnabled(false)

        block()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.setAnimationsEnabled(true)
        }
    }
}
