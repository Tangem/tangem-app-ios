//
//  BottomSheetPresentationController.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 15.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetPresentationController: UIPresentationController {
    let bottomSheetInteractiveDismissalTransition = BottomSheetDismissalTransition()

    let sheetCornerRadius: CGFloat
    let sheetBackgroundColor: UIColor
    var panToDismissEnabled: Bool = true

    private(set) lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan))
    private var heightConstraint: NSLayoutConstraint?
    private var currentHeight: CGFloat = 0 {
        didSet {
            bottomSheetInteractiveDismissalTransition.updateCurrentHeight(height: currentHeight)
        }
    }

    private var maxHeight: CGFloat {
        return UIScreen.main.bounds.height - (containerView?.safeAreaInsets.top ?? 0)
    }

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = sheetBackgroundColor
        view.alpha = 0
        view.layer.opacity = 0
        return view
    }()

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        sheetCornerRadius: CGFloat,
        sheetBackgroundColor: UIColor
    ) {
        self.sheetCornerRadius = sheetCornerRadius
        self.sheetBackgroundColor = sheetBackgroundColor
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override func presentationTransitionWillBegin() {
        guard let presentedView = presentedView else {
            return
        }

        presentedView.addGestureRecognizer(panGestureRecognizer)

        presentedView.layer.cornerRadius = sheetCornerRadius
        presentedView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
        ]

        guard let containerView = containerView else {
            return
        }

        containerView.addGestureRecognizer(tapGestureRecognizer)

        containerView.addSubview(backgroundView)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(
                equalTo: containerView.topAnchor
            ),
            backgroundView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor
            ),
            backgroundView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor
            ),
            backgroundView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor
            ),
        ])

        containerView.addSubview(presentedView)

        presentedView.translatesAutoresizingMaskIntoConstraints = false

        let preferredHeightConstraint = presentedView.heightAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.heightAnchor,
            multiplier: 0
        )

        preferredHeightConstraint.priority = .fittingSizeLevel

        let maxHeightConstraint = presentedView.topAnchor.constraint(
            greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor
        )

        maxHeightConstraint.priority = .required - 1

        let heightConstraint = presentedView.heightAnchor.constraint(
            equalToConstant: 0
        )

        let bottomConstraint = presentedView.bottomAnchor.constraint(
            equalTo: containerView.bottomAnchor
        )

        NSLayoutConstraint.activate([
            maxHeightConstraint,
            bottomConstraint,
            preferredHeightConstraint,

            presentedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            presentedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        ])

        bottomSheetInteractiveDismissalTransition.bottomConstraint = bottomConstraint
        bottomSheetInteractiveDismissalTransition.heightConstraint = heightConstraint
        self.heightConstraint = heightConstraint

        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }

        transitionCoordinator.animate { context in
            self.backgroundView.alpha = 1
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            backgroundView.removeFromSuperview()
            presentedView?.removeGestureRecognizer(panGestureRecognizer)
            containerView?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    override func dismissalTransitionWillBegin() {
        guard let transitionCoordinator = presentingViewController.transitionCoordinator else {
            return
        }

        transitionCoordinator.animate { context in
            self.backgroundView.alpha = 0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            backgroundView.removeFromSuperview()
            presentedView?.removeGestureRecognizer(panGestureRecognizer)
            containerView?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        panGestureRecognizer.isEnabled = false
        coordinator.animate(alongsideTransition: nil) { context in
            self.panGestureRecognizer.isEnabled = true
        }
    }

    func incrementHeight(by value: CGFloat) {
        let currentHeight = currentHeight == 0 ? (presentedView?.frame.height ?? 0) : currentHeight
        let incrementedHeight = currentHeight + value
        let changedHeight = incrementedHeight > maxHeight ? maxHeight : incrementedHeight
        self.currentHeight = changedHeight
        createHeightAnimator(height: changedHeight).startAnimation()
    }

    func decrementHeight(by value: CGFloat) {
        let currentHeight = currentHeight == 0 ? (presentedView?.frame.height ?? 0) : currentHeight
        let changedHeight = currentHeight - value
        self.currentHeight = changedHeight
        createHeightAnimator(height: changedHeight).startAnimation()
    }

    func updateHeightForPresentedView(with newHeight: CGFloat) {
        currentHeight = newHeight > maxHeight ? maxHeight : newHeight
        createHeightAnimator(height: currentHeight).startAnimation()
    }

    private func createHeightAnimator(height: CGFloat) -> UIViewPropertyAnimator {
        let propertyAnimator = UIViewPropertyAnimator(
            duration: 0.15,
            curve: .easeIn
        )

        heightConstraint?.isActive = true

        propertyAnimator.addAnimations {
            self.heightConstraint?.constant = height
            self.presentedView?.superview?.layoutIfNeeded()
        }

        return propertyAnimator
    }

    @objc
    private func onTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard
            let presentedView = presentedView,
            let containerView = containerView,
            !presentedView.frame.contains(gestureRecognizer.location(in: containerView))
        else {
            return
        }

        presentingViewController.dismiss(animated: true)
    }

    @objc
    private func onPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let presentedView = presentedView else {
            return
        }

        let translation = gestureRecognizer.translation(in: presentedView)
        let currentHeight = currentHeight == 0 ? presentedView.frame.height : currentHeight
        let progress = translation.y / currentHeight

        switch gestureRecognizer.state {
        case .began:
            bottomSheetInteractiveDismissalTransition.start(
                moving: presentedView, interactiveDismissal: panToDismissEnabled
            )
        case .changed:
            if panToDismissEnabled, progress > 0, !presentedViewController.isBeingDismissed {
                presentingViewController.dismiss(animated: true)
            }
            bottomSheetInteractiveDismissalTransition.move(
                presentedView, using: translation.y
            )
        default:
            let velocity = gestureRecognizer.velocity(in: presentedView)
            bottomSheetInteractiveDismissalTransition.stop(
                moving: presentedView, at: translation.y, with: velocity
            )
        }
    }
}
