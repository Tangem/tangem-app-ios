//
//  UIApplication+.swift
//  TangemUIKitUtils
//
//  Created by Alexander Osokin on 09.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

public extension UIApplication {
    static var safeAreaInsets: UIEdgeInsets {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets ?? .zero
    }
}
