//
//  BottomSheetBaseController.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 17.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetBaseController: UIViewController {
    override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            .custom
        }
        set {}
    }

    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            bottomSheetTransitioningDelegate
        }
        set {}
    }

    var cornerRadius: CGFloat = 8 {
        didSet {
            bottomSheetTransitioningDelegate.cornerRadius = cornerRadius
        }
    }

    var backgroundColor: UIColor = (UIColor(named: "BackgroundAction") ?? UIColor.black).withAlphaComponent(0.7) {
        didSet {
            bottomSheetTransitioningDelegate.backgroundColor = backgroundColor
        }
    }

    var contentBackgroundColor: UIColor = .white

    var tapOutsideToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.tapOutsideToDismissEnabled = tapOutsideToDismissEnabled
        }
    }

    var swipeDownToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.swipeDownToDismissEnabled = swipeDownToDismissEnabled
        }
    }

    func resize(withAction action: ResizeSheetAction) {
        bottomSheetTransitioningDelegate.resize(withAction: action)
    }

    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitionDelegate(
        cornerRadius: cornerRadius,
        backgroundColor: backgroundColor
    )
}
