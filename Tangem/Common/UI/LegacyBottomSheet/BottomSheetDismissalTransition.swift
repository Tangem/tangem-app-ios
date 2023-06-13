//
//  BottomSheetDismissalTransition.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 15.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit

class BottomSheetDismissalTransition: NSObject {
    var bottomConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?

    private let stretchOffset: CGFloat = 32
    private let maxTransitionDuration: CGFloat = 0.25
    private let minTransitionDuration: CGFloat = 0.15
    private let animationCurve: UIView.AnimationCurve = .easeIn

    private weak var transitionContext: UIViewControllerContextTransitioning?

    private var heightAnimator: UIViewPropertyAnimator?
    private var offsetAnimator: UIViewPropertyAnimator?

    private var interactiveDismissal: Bool = false
    private var presentedViewHeight: CGFloat = 0

    func start(moving presentedView: UIView, interactiveDismissal: Bool) {
        self.interactiveDismissal = interactiveDismissal

        heightAnimator?.stopAnimation(false)
        heightAnimator?.finishAnimation(at: .start)
        offsetAnimator?.stopAnimation(false)
        offsetAnimator?.finishAnimation(at: .start)

        let currentHeight = presentedViewHeight == 0 ? presentedView.frame.height : presentedViewHeight

        heightAnimator = createHeightAnimator(
            animating: presentedView, from: currentHeight
        )

        if !interactiveDismissal {
            offsetAnimator = createOffsetAnimator(
                animating: presentedView, to: stretchOffset
            )
        }
    }

    func move(_ presentedView: UIView, using translation: CGFloat) {
        let currentHeight = presentedViewHeight == 0 ? presentedView.frame.height : presentedViewHeight
        let progress = translation / currentHeight

        let stretchProgress = stretchProgress(basedOn: translation)

        heightAnimator?.fractionComplete = stretchProgress * -1
        offsetAnimator?.fractionComplete = interactiveDismissal ? progress : stretchProgress

        transitionContext?.updateInteractiveTransition(progress)
    }

    func stop(moving presentedView: UIView, at translation: CGFloat, with velocity: CGPoint) {
        let currentHeight = presentedViewHeight == 0 ? presentedView.frame.height : presentedViewHeight
        let progress = translation / currentHeight

        let stretchProgress = stretchProgress(basedOn: translation)

        heightAnimator?.fractionComplete = stretchProgress * -1
        offsetAnimator?.fractionComplete = interactiveDismissal ? progress : stretchProgress

        transitionContext?.updateInteractiveTransition(progress)

        let cancelDismiss = !interactiveDismissal || velocity.y < 500 || (progress < 0.5 && velocity.y <= 0)

        heightAnimator?.isReversed = true
        offsetAnimator?.isReversed = cancelDismiss && progress <= 0.45

        if cancelDismiss, progress <= 0.45 {
            transitionContext?.cancelInteractiveTransition()
        } else {
            transitionContext?.finishInteractiveTransition()
        }

        if transitionContext?.isInteractive ?? true {
            heightAnimator?.continueAnimation(
                withTimingParameters: nil,
                durationFactor: 0
            )
        }
        offsetAnimator?.continueAnimation(
            withTimingParameters: nil,
            durationFactor: 0
        )

        interactiveDismissal = false
    }

    func updateCurrentHeight(height: CGFloat) {
        presentedViewHeight = height
    }
}

// MARK: UIViewControllerAnimatedTransitioning

extension BottomSheetDismissalTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        maxTransitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: .from) else {
            return
        }

        offsetAnimator?.stopAnimation(true)

        let currentHeight = presentedViewHeight == 0 ? presentedView.frame.height : presentedViewHeight

        let offset = currentHeight
        let offsetAnimator = createOffsetAnimator(animating: presentedView, to: offset)

        offsetAnimator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        offsetAnimator.startAnimation()

        self.offsetAnimator = offsetAnimator
    }

    func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        guard let offsetAnimator = offsetAnimator else {
            fatalError("Somehow the offset animator was not set")
        }

        return offsetAnimator
    }
}

// MARK: UIViewControllerInteractiveTransitioning

extension BottomSheetDismissalTransition: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard
            transitionContext.isInteractive,
            let presentedView = transitionContext.view(forKey: .from)
        else {
            return animateTransition(using: transitionContext)
        }

        offsetAnimator?.stopAnimation(true)

        let currentHeight = presentedViewHeight == 0 ? presentedView.frame.height : presentedViewHeight

        let offset = currentHeight
        let offsetAnimator = createOffsetAnimator(animating: presentedView, to: offset)

        offsetAnimator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        offsetAnimator.fractionComplete = 0

        transitionContext.updateInteractiveTransition(0)

        self.offsetAnimator = offsetAnimator
        self.transitionContext = transitionContext
    }

    var wantsInteractiveStart: Bool {
        interactiveDismissal
    }

    var completionCurve: UIView.AnimationCurve {
        animationCurve
    }

    var completionSpeed: CGFloat {
        1.0
    }
}

//  MARK: - Private

extension BottomSheetDismissalTransition {
    private func createHeightAnimator(animating view: UIView, from height: CGFloat) -> UIViewPropertyAnimator {
        let propertyAnimator = UIViewPropertyAnimator(
            duration: minTransitionDuration,
            curve: animationCurve
        )

        heightConstraint?.constant = height
        heightConstraint?.isActive = true

        let finalHeight = height + stretchOffset

        propertyAnimator.addAnimations {
            self.heightConstraint?.constant = finalHeight
            view.superview?.layoutIfNeeded()
        }

        propertyAnimator.addCompletion { position in
            self.heightConstraint?.constant = position == .end ? finalHeight : height
        }

        return propertyAnimator
    }

    private func createOffsetAnimator(animating view: UIView, to offset: CGFloat) -> UIViewPropertyAnimator {
        let propertyAnimator = UIViewPropertyAnimator(
            duration: maxTransitionDuration,
            curve: animationCurve
        )

        propertyAnimator.addAnimations {
            self.bottomConstraint?.constant = offset
            view.superview?.layoutIfNeeded()
        }

        propertyAnimator.addCompletion { position in
            self.bottomConstraint?.constant = position == .end ? offset : 0
        }

        return propertyAnimator
    }

    private func stretchProgress(basedOn translation: CGFloat) -> CGFloat {
        (translation > 0 ? pow(translation, 0.33) : -pow(-translation, 0.33)) / stretchOffset
    }
}
