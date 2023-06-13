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
    static var topViewController: UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        return keyWindow?.topViewController
    }

    static func modalFromTop(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else { return }

        if top.isBeingDismissed {
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

extension UIApplication {
    static var safeAreaInsets: UIEdgeInsets {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets ?? .zero
    }
}
