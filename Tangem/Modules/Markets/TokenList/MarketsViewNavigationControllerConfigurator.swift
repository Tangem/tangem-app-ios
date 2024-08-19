//
//  MarketsViewNavigationControllerConfigurator.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class MarketsViewNavigationControllerConfigurator: NSObject, ObservableObject {
    func configure(_ navigationController: UINavigationController) {
        if !navigationController.navigationBar.isHidden {
            // Unlike `UINavigationController.setNavigationBarHidden(_:animated:)` from UIKit and `navigationBarHidden(_:)`
            // from SwiftUI, this approach will hide the navigation bar without breaking the swipe-to-pop gesture
            navigationController.navigationBar.isHidden = true
        }
    }
}
