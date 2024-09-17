//
//  OverlayContentContainerViewControllerDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 17.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

protocol OverlayContentContainerViewControllerDelegate: AnyObject {
    func controller(
        _ controller: OverlayContentContainerViewController,
        wantsAlternativePresentationForOverlayViewController overlayViewController: UIViewController
    )

    func controller(
        _ controller: OverlayContentContainerViewController,
        wantsDefaultPresentationForOverlayViewController overlayViewController: UIViewController
    )
}
