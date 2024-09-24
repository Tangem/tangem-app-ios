//
//  MainCoordinatorNavigationAssertion.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class MainCoordinatorNavigationAssertion: NSObject, ObservableObject {
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
}

// MARK: - UINavigationControllerDelegate protocol conformance

extension MainCoordinatorNavigationAssertion: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        // We care only about navigation from the root VC to the child VCs, not the other way around
        guard navigationController.viewControllers.count > 1 else {
            return
        }

        if !mainBottomSheetUIManager.isShown || mainBottomSheetUIManager.hasPendingSnapshotUpdate {
            return
        }

        assertionFailure("Hide the main bottom sheet using `mainBottomSheetUIManager.hide()` API in `MainCoordinator` before triggering push navigation")
    }
}
