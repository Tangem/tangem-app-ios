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
    private var cornerRadius: CGFloat = .zero

    func setCornerRadius(_ cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    func configure(_ navigationController: UINavigationController) {
        navigationController.setNavigationBarAlwaysHidden()
        navigationController.setDelegateSafe(self)
    }
}

// MARK: - UINavigationControllerDelegate protocol conformance

extension MarketsViewNavigationControllerConfigurator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        // Rounded corners should be applied only to children VCs, leaving the root VC intact
        guard viewController !== navigationController.viewControllers.first else {
            return
        }

        if !viewController.isViewLoaded {
            AppLog.info("Configurator will force load the root view of the view controller \(viewController)")
        }

        // Applying rounded corners in SwiftUI still leaves a white background underneath, so we're left with UIKit
        viewController.view.layer.cornerRadius(cornerRadius, corners: .topEdge)
    }
}
