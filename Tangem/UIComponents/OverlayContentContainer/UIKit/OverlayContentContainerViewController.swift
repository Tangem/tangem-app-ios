//
//  OverlayContentContainerViewController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemUIKitUtils

final class OverlayContentContainerViewController: UIViewController {
    // MARK: - Dependencies

    let overlayCornerRadius: CGFloat

    private let contentViewController: UIViewController
    private let contentExpandedVerticalOffset: CGFloat
    private let overlayCollapsedHeight: CGFloat
    private var overlayCollapsedVerticalOffset: CGFloat { screenBounds.height - overlayCollapsedHeight }

    // MARK: - Mutable state

    private var overlayViewController: UIViewController?
    private var panGestureStartLocationInScreenCoordinateSpace: CGPoint = .zero
    private var panGestureStartLocationInOverlayViewCoordinateSpace: CGPoint = .zero
    private var shouldIgnorePanGestureRecognizer = false
    private var didTap = false

    private var progress: OverlayContentContainerProgress = .zero {
        didSet { onProgressChange(oldValue: oldValue, newValue: progress) }
    }

    private var stateObservers: [AnyHashable: OverlayContentStateObserver.StateObserver] = [:]
    private var progressObservers: [AnyHashable: OverlayContentStateObserver.ProgressObserver] = [:]

    // MARK: - Read-only state

    var isScrollViewLocked: Bool { scrollViewContentOffsetLocker?.isLocked ?? false }

    private var screenBounds: CGRect {
        return UIScreen.main.bounds
    }

    private var adjustedContentOffset: CGPoint {
        return scrollViewContentOffsetLocker?.scrollView.adjustedContentOffset ?? .zero
    }

    private var isExpandedState: Bool {
        return abs(1.0 - progress.value) <= .ulpOfOne
    }

    private var isCollapsedState: Bool {
        return abs(progress.value) <= .ulpOfOne
    }

    /// I.e. either collapsed or expanded.
    private var isFinalState: Bool {
        return isExpandedState || isCollapsedState
    }

    private var minBackgroundShadowViewAlpha: CGFloat { .zero }

    private var maxBackgroundShadowViewAlpha: CGFloat {
        traitCollection.isDarkMode
            ? Constants.maxBackgroundShadowViewAlphaForDarkUserInterfaceStyle
            : Constants.maxBackgroundShadowViewAlphaForLightUserInterfaceStyle
    }

    // MARK: - IBOutlets/UI

    private var overlayViewTopAnchorConstraint: NSLayoutConstraint?
    private var grabberView: UIView?
    private lazy var backgroundShadowView = UIView(frame: screenBounds)
    private lazy var tapGestureRecognizerHostingView = TouchPassthroughView()

    // MARK: - Helpers

    private var scrollViewContentOffsetLocker: ScrollViewContentOffsetLocker?
    private lazy var appLifecycleHelper = OverlayContentContainerAppLifecycleHelper()
    private lazy var gestureConflictResolver = SwiftUIGestureConflictResolver()

    // MARK: - Initialization/Deinitialization

    /// - Note: All height/offset parameters (`overlayCollapsedHeight`, `contentExpandedVerticalOffset`, etc)
    /// are relative to the main screen bounds (w/o safe area).
    init(
        contentViewController: UIViewController,
        contentExpandedVerticalOffset: CGFloat,
        overlayCollapsedHeight: CGFloat,
        overlayCornerRadius: CGFloat
    ) {
        self.contentViewController = contentViewController
        self.contentExpandedVerticalOffset = Self.calculateContentExpandedVerticalOffset(fromInput: contentExpandedVerticalOffset)
        self.overlayCollapsedHeight = overlayCollapsedHeight
        self.overlayCornerRadius = overlayCornerRadius
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "init(coder:) has not been implemented")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // The order in which all these methods are called matters, change it with caution
        setupView()
        setupTapGestureRecognizer()
        setupPanGestureRecognizer()
        setupContent()
        setupBackgroundShadowView()
        setupTapGestureRecognizerHostingView()
        setupOverlayIfAvailable()
        setupAppLifecycleHelper()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let grabberView {
            grabberView.superview?.bringSubviewToFront(grabberView)
        }

        backgroundShadowView.superview?.bringSubviewToFront(backgroundShadowView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateBackgroundShadowViewBackgroundColor()
            updateBackgroundShadowViewAlpha()
        }
    }

    // MARK: - Public API

    func installOverlay(_ newOverlayViewController: UIViewController) {
        guard overlayViewController == nil else {
            assertionFailure("Remove previous overlay view controller using `removeOverlay` before installing a new one")
            return
        }

        guard isViewLoaded else {
            // Overlay (if any) will be installed in `viewDidLoad` later on
            return
        }

        overlayViewController = newOverlayViewController
        setupOverlay(newOverlayViewController)
    }

    func removeOverlay() {
        guard let overlayViewController else {
            return
        }

        reset() // Crucial for tearing down the KVO observation (if any)

        overlayViewController.willMove(toParent: nil)

        overlayViewTopAnchorConstraint?.isActive = false
        overlayViewTopAnchorConstraint = nil

        grabberView = nil

        let overlayView = overlayViewController.view!
        overlayView.removeFromSuperview()

        overlayViewController.removeFromParent()
        self.overlayViewController = nil

        updateProgress(verticalOffset: overlayCollapsedVerticalOffset, animationContext: nil)
    }

    /// An ugly workaround due to navigation issues in SwiftUI on iOS 18 and above, see IOS-7990 for details.
    /// Normally, the overlay is intended to be hidden/shown using the `installOverlay`/`removeOverlay` API.
    func setOverlayHidden(_ isHidden: Bool) {
        overlayViewController?.viewIfLoaded?.isHidden = isHidden
    }

    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    /// Remove this reference by using `removeObserver(forToken:)` method.
    func addObserver(_ observer: @escaping OverlayContentStateObserver.StateObserver, forToken token: any Hashable) {
        stateObservers[AnyHashable(token)] = observer
    }

    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    /// Remove this reference by using `removeObserver(forToken:)` method.
    func addObserver(_ observer: @escaping OverlayContentStateObserver.ProgressObserver, forToken token: any Hashable) {
        progressObservers[AnyHashable(token)] = observer
    }

    func removeObserver(forToken token: any Hashable) {
        stateObservers.removeValue(forKey: AnyHashable(token))
        progressObservers.removeValue(forKey: AnyHashable(token))
    }

    func expand() {
        let newVerticalOffset = contentExpandedVerticalOffset
        overlayViewTopAnchorConstraint?.constant = newVerticalOffset

        var animationContext = Constants.defaultAnimationContext
        UIView.animate(with: animationContext) {
            self.view.layoutIfNeeded()
        }

        // `auxiliary` animations (content scale, corner radius, etc) are baked by Core Animation and don't use
        // spring animations. Since these are plain, non-spring animations, they don't oscillate and therefore
        // have a slightly shorter duration than `animationContext.duration`.
        // That difference in duration is provided by multiplying by `auxiliaryAnimationsDurationMultiplier`
        animationContext.duration *= Constants.auxiliaryAnimationsDurationMultiplier

        updateProgress(verticalOffset: newVerticalOffset, animationContext: animationContext)
    }

    func collapse() {
        let newVerticalOffset = overlayCollapsedVerticalOffset
        overlayViewTopAnchorConstraint?.constant = newVerticalOffset

        var animationContext = Constants.defaultAnimationContext
        UIView.animate(with: animationContext) {
            self.view.layoutIfNeeded()
        }

        // `auxiliary` animations (content scale, corner radius, etc) are baked by Core Animation and don't use
        // spring animations. Since these are plain, non-spring animations, they don't oscillate and therefore
        // have a slightly shorter duration than `animationContext.duration`.
        // That difference in duration is provided by multiplying by `auxiliaryAnimationsDurationMultiplier`
        animationContext.duration *= Constants.auxiliaryAnimationsDurationMultiplier

        updateProgress(verticalOffset: newVerticalOffset, animationContext: animationContext)
    }

    // Workaround: If you open the markets screen, add a token, and return to the main page, the frames break and no longer align with the tap zone.
    // https://tangem.atlassian.net/browse/IOS-8705
    // https://forums.developer.apple.com/forums/thread/724598
    func resetContentFrame() {
        let viewFrame = contentViewController.view.frame
        contentViewController.view.frame = .zero
        contentViewController.view.frame = viewFrame
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .black
    }

    private func setupBackgroundShadowView() {
        backgroundShadowView.alpha = minBackgroundShadowViewAlpha
        backgroundShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundShadowView.isUserInteractionEnabled = false
        contentViewController.view.addSubview(backgroundShadowView)
        updateBackgroundShadowViewBackgroundColor()
    }

    private func setupContent() {
        addChild(contentViewController)

        let containerView = view!
        let contentView = contentViewController.view!
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: screenBounds.height),
            contentView.widthAnchor.constraint(equalToConstant: screenBounds.width),
        ])

        // Actual value for the `cornerRadius` CALayer property will be assigned later in `updateCornerRadius`
        contentView.layer.cornerRadius(.zero, corners: .topEdge)
        contentViewController.didMove(toParent: self)
    }

    private func setupOverlayIfAvailable() {
        if let overlayViewController {
            setupOverlay(overlayViewController)
        }
    }

    private func setupOverlay(_ overlayViewController: UIViewController) {
        addChild(overlayViewController)

        let containerView = view!
        let overlayView = overlayViewController.view!
        containerView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        // `overlayView` always must be placed under `tapGestureRecognizerHostingView`
        containerView.insertSubview(overlayView, belowSubview: tapGestureRecognizerHostingView)

        let overlayViewTopAnchorConstraint = overlayView
            .topAnchor
            .constraint(equalTo: containerView.topAnchor, constant: overlayCollapsedVerticalOffset)
        self.overlayViewTopAnchorConstraint = overlayViewTopAnchorConstraint

        NSLayoutConstraint.activate([
            overlayViewTopAnchorConstraint,
            overlayView.heightAnchor.constraint(equalToConstant: screenBounds.height),
            overlayView.widthAnchor.constraint(equalToConstant: screenBounds.width),
        ])

        let grabberViewFactory = GrabberViewFactory()
        let grabberView = grabberViewFactory.makeUIKitView()
        self.grabberView = grabberView

        overlayView.addSubview(grabberView)
        grabberView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true

        overlayView.layer.cornerRadius(overlayCornerRadius, corners: .topEdge)
        overlayViewController.additionalSafeAreaInsets.bottom = contentExpandedVerticalOffset // Over-scroll compensation
        overlayViewController.didMove(toParent: self)
    }

    private func setupTapGestureRecognizerHostingView() {
        tapGestureRecognizerHostingView.delegate = self
        tapGestureRecognizerHostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tapGestureRecognizerHostingView)
        NSLayoutConstraint.activate([
            tapGestureRecognizerHostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapGestureRecognizerHostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tapGestureRecognizerHostingView.topAnchor.constraint(equalTo: view.topAnchor),
            tapGestureRecognizerHostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapGesture(_:)))
        tapGestureRecognizerHostingView.addGestureRecognizer(gestureRecognizer)
    }

    private func setupPanGestureRecognizer() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    private func setupAppLifecycleHelper() {
        appLifecycleHelper.delegate = self
        appLifecycleHelper.observeLifecycleIfNeeded()
    }

    // MARK: - State update

    private func updateProgress(verticalOffset: CGFloat, animationContext: OverlayContentContainerProgress.AnimationContext?) {
        let value = clamp(
            (overlayCollapsedVerticalOffset - verticalOffset) / (overlayCollapsedVerticalOffset - contentExpandedVerticalOffset),
            min: 0.0,
            max: 1.0
        )

        progress = OverlayContentContainerProgress(value: value, context: animationContext)
    }

    private func updateContentScale() {
        let contentLayer = contentViewController.view.layer
        let invertedProgress = 1.0 - progress.value
        let minContentViewScale = (screenBounds.height - contentExpandedVerticalOffset + Constants.overlayVerticalPadding) / screenBounds.height
        let scale = minContentViewScale + (Constants.maxContentViewScale - minContentViewScale) * invertedProgress

        if isFinalState, let animationContext = progress.context {
            let keyPath = String(_sel: #selector(getter: CALayer.transform))
            let animation = CABasicAnimation(keyPath: keyPath)
            animation.duration = animationContext.duration
            animation.timingFunction = animationContext.curve.toMediaTimingFunction()
            contentLayer.add(animation, forKey: #function)
        }

        let transform: CGAffineTransform = .scaleTransform(
            for: contentLayer.bounds.size,
            scaledBy: .init(x: scale, y: scale),
            aroundAnchorPoint: .init(x: 0.5, y: 1.0) // Bottom center
        )

        contentLayer.setAffineTransform(transform)

        // Workaround: prevents the navigation bar in the `contentViewController` from being laid out incorrectly
        // Without this workaround, the `frame.origin.y` property of the navigation bar may be set to zero in some cases,
        // resulting in an incorrect layout of the status bar
        if UIDevice.current.hasHomeScreenIndicator {
            contentViewController.additionalSafeAreaInsets.top = contentLayer.frame.minY
        } else {
            // On notchless devices, some additional math is needed due to the existence of
            // `Constants.notchlessDevicesAdditionalVerticalPadding` constant
            let additionalVerticalPadding = Constants.notchlessDevicesAdditionalVerticalPadding
            let minSafeAreaTopInset = UIApplication.safeAreaInsets.top
            let maxSafeAreaTopInset = minSafeAreaTopInset + additionalVerticalPadding
            let lowerBound = minSafeAreaTopInset / maxSafeAreaTopInset // Essentially 2/3
            let upperBound = maxSafeAreaTopInset / maxSafeAreaTopInset // Essentially 1.0
            let progress = progress.value.interpolatedProgress(inRange: lowerBound ... upperBound)
            contentViewController.additionalSafeAreaInsets.top = contentLayer.frame.minY - progress * additionalVerticalPadding
        }
    }

    private func updateCornerRadius() {
        let contentLayer = contentViewController.view.layer

        // On devices with a notch, the corner radius property isn't animated and always has a constant value
        // (`overlayCornerRadius`) UNLESS it's completely invisible and hidden behind screen borders.
        // In the latter case, the corner radius property is set to zero,
        // which prevents screenshots from being spoiled and other similar issues
        if UIDevice.current.hasHomeScreenIndicator {
            if isCollapsedState {
                // Wait for the collapsing animation to finish
                CATransaction.setCompletionBlock {
                    contentLayer.cornerRadius = .zero
                }
            } else {
                contentLayer.cornerRadius = overlayCornerRadius
            }
        } else {
            if isFinalState, let animationContext = progress.context {
                let keyPath = String(_sel: #selector(getter: CALayer.cornerRadius))
                let animation = CABasicAnimation(keyPath: keyPath)
                animation.duration = animationContext.duration
                animation.timingFunction = animationContext.curve.toMediaTimingFunction()
                contentLayer.add(animation, forKey: #function)
            }

            contentLayer.cornerRadius = overlayCornerRadius * progress.value
        }
    }

    private func updateBackgroundShadowViewBackgroundColor() {
        backgroundShadowView.backgroundColor = traitCollection.isDarkMode ? .white : .black
    }

    private func updateBackgroundShadowViewAlpha() {
        let alpha = minBackgroundShadowViewAlpha + (maxBackgroundShadowViewAlpha - minBackgroundShadowViewAlpha) * progress.value

        if isFinalState, let animationContext = progress.context {
            UIView.animate(with: animationContext) {
                self.backgroundShadowView.alpha = alpha
            }
        } else {
            backgroundShadowView.alpha = alpha
        }
    }

    private func notifyStateObserversIfNeeded(isCollapsedState: Bool, isExpandedState: Bool) {
        for stateObserver in stateObservers.values {
            if isCollapsedState {
                stateObserver(.collapsed)
            } else if isExpandedState {
                let trigger: OverlayContentState.Trigger = didTap ? .tapGesture : .dragGesture
                stateObserver(.expanded(trigger: trigger))
            } else {
                // No-op
            }
        }
    }

    private func notifyProgressObservers(progressValue: CGFloat) {
        for progressObserver in progressObservers.values {
            progressObserver(progressValue)
        }
    }

    private func reset() {
        panGestureStartLocationInScreenCoordinateSpace = .zero
        panGestureStartLocationInOverlayViewCoordinateSpace = .zero
        shouldIgnorePanGestureRecognizer = false
        scrollViewContentOffsetLocker = nil
    }

    // MARK: - Handlers

    private func onProgressChange(oldValue: OverlayContentContainerProgress, newValue: OverlayContentContainerProgress) {
        guard oldValue != newValue else {
            return
        }

        updateContentScale()
        updateCornerRadius()
        updateBackgroundShadowViewAlpha()
        notifyStateObserversIfNeeded(isCollapsedState: isCollapsedState, isExpandedState: isExpandedState)
        notifyProgressObservers(progressValue: newValue.value)

        if didTap {
            didTap = false
        }
    }

    @objc
    private func onTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        didTap = true
        expand()
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            if didTap {
                didTap = false
            }
        case .changed:
            onPanGestureChanged(gestureRecognizer)
        case .ended:
            onPanGestureEnded(gestureRecognizer)
        case .cancelled, .failed:
            reset()
        case .possible, .recognized:
            break
        @unknown default:
            assertionFailure("Unknown state received \(gestureRecognizer.state)")
        }
    }

    func onPanGestureChanged(_ gestureRecognizer: UIPanGestureRecognizer) {
        if shouldIgnorePanGestureRecognizer {
            return
        }

        let verticalDirection = verticalDirection(for: gestureRecognizer)

        switch verticalDirection {
        case _ where scrollViewContentOffsetLocker == nil:
            // There is no scroll view in the overlay view, use default logic
            break
        case .up where isExpandedState && scrollViewContentOffsetLocker?.isLocked == false:
            // Normal scrolling to the bottom of the scroll view content, pan gesture recognizer should be ignored
            // for the entire duration of the gesture (until end)
            shouldIgnorePanGestureRecognizer = true
            return
        case .up where isCollapsedState:
            // Expanding overlay using pan gesture, the scroll view content offset should remain intact,
            // so we lock it and then use default logic
            scrollViewContentOffsetLocker?.lock()
        case .down where adjustedContentOffset.y <= Constants.minAdjustedContentOffsetToLockScrollView:
            // Collapsing overlay using pan gesture, the scroll view content offset should remain intact,
            // so we lock it and then use default logic
            scrollViewContentOffsetLocker?.lock()
        case .down where adjustedContentOffset != .zero && scrollViewContentOffsetLocker?.isLocked == false:
            // Normal scrolling to the top of the scroll view content, pan gesture recognizer should be ignored
            // for the entire duration of the gesture (until end)
            shouldIgnorePanGestureRecognizer = true
            return
        default:
            break
        }

        let translation = gestureRecognizer.translation(in: nil)
        let currentVerticalOffset = overlayViewTopAnchorConstraint?.constant ?? .zero
        let clampedNewVerticalOffset = clamp(
            currentVerticalOffset + translation.y,
            min: contentExpandedVerticalOffset,
            max: overlayCollapsedVerticalOffset
        )
        let verticalOffsetRubberbandingComponent = calculateVerticalOffsetRubberbandingComponent(gestureRecognizer)
        let newVerticalOffset = max(clampedNewVerticalOffset + verticalOffsetRubberbandingComponent, .zero)

        overlayViewTopAnchorConstraint?.constant = newVerticalOffset
        gestureRecognizer.setTranslation(.zero, in: nil)

        updateProgress(verticalOffset: newVerticalOffset, animationContext: nil)
        gestureConflictResolver.onUIKitGestureStart()
    }

    func onPanGestureEnded(_ gestureRecognizer: UIPanGestureRecognizer) {
        defer {
            gestureConflictResolver.onUIKitGestureEnd()
            reset()
        }

        if shouldIgnorePanGestureRecognizer {
            return
        }

        // The 'raw' and 'true' velocity of a pan gesture appeared to be too fast for the smooth gesture-driven animation.
        // Therefore, we reduce the velocity a bit by multiplying it by `panGestureVerticalVelocityMultiplier`,
        // while keeping the gesture-driven look & feel for the animation
        let velocity = gestureRecognizer.velocity(in: nil) * Constants.panGestureVerticalVelocityMultiplier
        let verticalDirection = verticalDirection(for: gestureRecognizer)
        let decelerationRate = calculateDecelerationRate(gestureVerticalDirection: verticalDirection)
        let predictedEndLocation = gestureRecognizer.predictedEndLocation(in: nil, atDecelerationRate: decelerationRate)
        let predictedOverlayViewFrameOrigin = predictedEndLocation - panGestureStartLocationInOverlayViewCoordinateSpace
        let isCollapsing = predictedOverlayViewFrameOrigin.y > screenBounds.height / 2.0

        let (animationDuration, remainingDistance) = calculateAnimationDurationAndRemainingDistance(
            isCollapsing: isCollapsing,
            gestureVelocity: velocity,
            gestureVerticalDirection: verticalDirection
        )

        var animationContext = makeGestureDrivenAnimationContext(
            isCollapsing: isCollapsing,
            gestureVelocity: velocity,
            animationDuration: animationDuration,
            remainingDistance: remainingDistance
        )

        let newVerticalOffset = isCollapsing ? overlayCollapsedVerticalOffset : contentExpandedVerticalOffset
        overlayViewTopAnchorConstraint?.constant = newVerticalOffset

        UIView.animate(
            with: animationContext,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.view.layoutIfNeeded()
        }

        // `auxiliary` animations (content scale, corner radius, etc) are baked by Core Animation and don't use
        // spring animations. Since these are plain, non-spring animations, they don't oscillate and therefore
        // have a slightly shorter duration than `animationContext.duration`.
        // That difference in duration is provided by multiplying by `auxiliaryAnimationsDurationMultiplier`
        animationContext.duration *= Constants.auxiliaryAnimationsDurationMultiplier

        updateProgress(verticalOffset: newVerticalOffset, animationContext: animationContext)
    }

    // MARK: - Helpers

    private func verticalDirection(for gestureRecognizer: UIPanGestureRecognizer) -> UIPanGestureRecognizer.VerticalDirection? {
        let startLocation = panGestureStartLocationInScreenCoordinateSpace
        return gestureRecognizer.verticalDirection(in: nil, relativeToGestureStartLocation: startLocation)
    }

    private func makeGestureDrivenAnimationContext(
        isCollapsing: Bool,
        gestureVelocity: CGPoint,
        animationDuration: TimeInterval,
        remainingDistance: CGFloat
    ) -> OverlayContentContainerProgress.AnimationContext {
        var animationContext = Constants.defaultAnimationContext
        animationContext.duration = animationDuration

        if remainingDistance > 0 {
            // `UIView.animate(withDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)`
            // uses quite weird velocity units - 'distances' per second, not points per second
            animationContext.initialSpringVelocity = abs(gestureVelocity.y / remainingDistance)
        }

        // Spring animation is only applied when the overlay view is in the expanded state;
        // to prevent a fake footer view, placed on the main view, from becoming visible
        if isCollapsing {
            animationContext.disableSpringAnimation()
        }

        return animationContext
    }

    private func calculateDecelerationRate(
        gestureVerticalDirection: UIPanGestureRecognizer.VerticalDirection?
    ) -> UIScrollView.DecelerationRate {
        // Makes the overlay view easier to expand and a bit harder to collapse
        switch gestureVerticalDirection {
        case .down:
            return .fast
        case .up,
             .none:
            return .normal
        }
    }

    private func calculateAnimationDurationAndRemainingDistance(
        isCollapsing: Bool,
        gestureVelocity: CGPoint,
        gestureVerticalDirection: UIPanGestureRecognizer.VerticalDirection?
    ) -> (animationDuration: TimeInterval, remainingDistance: CGFloat) {
        let gestureVelocityVerticalDirection: UIPanGestureRecognizer.VerticalDirection = gestureVelocity.y < .zero
            ? .up
            : .down

        // Equals `true` when a user tries to collapse or expand the overlay view with a pan gesture
        // but ultimately fails to do so (e.g., the velocity of the pan gesture is too low)
        let isGestureFailed = (isCollapsing && gestureVerticalDirection == .up && gestureVelocityVerticalDirection == .up)
            || (!isCollapsing && gestureVerticalDirection == .down && gestureVelocityVerticalDirection == .down)

        let verticalOffset = overlayViewTopAnchorConstraint?.constant ?? .greatestFiniteMagnitude
        let isOverScroll = verticalOffset < contentExpandedVerticalOffset
        let overlayViewFrame = overlayViewController?.view.frame ?? .zero

        let remainingDistance = isCollapsing
            ? max(overlayCollapsedVerticalOffset - overlayViewFrame.minY, .zero)
            : max(overlayViewFrame.minY - contentExpandedVerticalOffset, .zero)

        if isGestureFailed || isOverScroll {
            // We don't take gesture velocity into account if the gesture fails or if there is an over-scroll
            return (Constants.failedGestureAnimationsDuration, remainingDistance)
        }

        let animationDuration = clamp(
            remainingDistance / abs(gestureVelocity.y),
            min: Constants.minAnimationsDuration,
            max: Constants.maxAnimationsDuration
        )

        return (animationDuration, remainingDistance)
    }

    private func calculateVerticalOffsetRubberbandingComponent(_ gestureRecognizer: UIPanGestureRecognizer) -> CGFloat {
        let gestureLocation = gestureRecognizer.location(in: nil)
        let draggedOverlayViewFrameOrigin = gestureLocation - panGestureStartLocationInOverlayViewCoordinateSpace

        // Rubberbanding is only applied when the overlay view is in the expanded state;
        // to prevent a fake footer view, placed on the main view, from becoming visible
        guard draggedOverlayViewFrameOrigin.y < contentExpandedVerticalOffset else {
            return .zero
        }

        return (draggedOverlayViewFrameOrigin.y - contentExpandedVerticalOffset).withRubberbanding()
    }

    private static func calculateContentExpandedVerticalOffset(fromInput contentExpandedVerticalOffset: CGFloat) -> CGFloat {
        var offset = contentExpandedVerticalOffset + Constants.overlayVerticalPadding

        if !UIDevice.current.hasHomeScreenIndicator {
            offset += Constants.notchlessDevicesAdditionalVerticalPadding
        }

        return offset
    }
}

// MARK: - UIGestureRecognizerDelegate protocol conformance

extension OverlayContentContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let overlayView = overlayViewController?.viewIfLoaded else {
            return false
        }

        let locationInScreenCoordinateSpace = touch.location(in: nil)
        panGestureStartLocationInScreenCoordinateSpace = locationInScreenCoordinateSpace
        panGestureStartLocationInOverlayViewCoordinateSpace = touch.location(in: overlayView)

        // The gesture is completely disabled if no overlay view controller is set or the overlay view isn't visible (hidden)
        return overlayView.frame.contains(locationInScreenCoordinateSpace) && !overlayView.isHidden
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGestureRecognizer.velocity(in: nil)

        // Trigger pan-to-collapse logic only on a vertical pan gesture
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            if scrollViewContentOffsetLocker?.scrollView !== scrollView {
                scrollViewContentOffsetLocker = .make(for: scrollView)
            }
        } else {
            gestureConflictResolver.handleSwiftUIGestureIfNeeded(otherGestureRecognizer)
        }

        return true
    }
}

// MARK: - TouchPassthroughViewDelegate protocol conformance

extension OverlayContentContainerViewController: TouchPassthroughViewDelegate {
    func touchPassthroughView(
        _ passthroughView: TouchPassthroughView,
        shouldPassthroughTouchAt point: CGPoint,
        with event: UIEvent?
    ) -> Bool {
        guard
            let overlayView = overlayViewController?.viewIfLoaded
        else {
            return true
        }

        let overlayViewFrame = overlayView.frame
        let touchPoint = view.convert(point, from: passthroughView)

        // Tap gesture recognizer should only be triggered if the touch location is within the collapsed overlay view
        // and this view is visible (not hidden)
        let shouldRecognizeTouch = overlayViewFrame.contains(touchPoint) && isCollapsedState && !overlayView.isHidden

        return !shouldRecognizeTouch
    }
}

// MARK: - OverlayContentContainerAppLifecycleHelperDelegate protocol conformance

extension OverlayContentContainerViewController: OverlayContentContainerAppLifecycleHelperDelegate {
    func currentProgress(for appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) -> CGFloat {
        return progress.value
    }

    func appLifecycleHelperDidTriggerExpand(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) {
        expand()
    }

    func appLifecycleHelperDidTriggerCollapse(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) {
        collapse()
    }
}

// MARK: - Constants

private extension OverlayContentContainerViewController {
    enum Constants {
        /// Vertical padding between the top edge of the `content` (a view in the background)
        /// and the top edge of the `overlay` (a view in front) in expanded state.
        /// Value of 10.0pt is the same value that the native iOS sheet uses.
        static let overlayVerticalPadding = 10.0
        /// On notchless devices, the native iOS sheet adds additional vertical padding to the `safeAreaInsets.top`
        /// to ensure that there is enough free space between the status bar and the top edge of the sheet.
        /// Value of 10.0pt is the same value that the native iOS sheet uses.
        static let notchlessDevicesAdditionalVerticalPadding = 10.0
        static let maxContentViewScale = 1.0
        static let maxBackgroundShadowViewAlphaForLightUserInterfaceStyle = 0.4
        static let maxBackgroundShadowViewAlphaForDarkUserInterfaceStyle = 0.08
        static let minAdjustedContentOffsetToLockScrollView = 10.0
        static let panGestureVerticalVelocityMultiplier = 2.0 / 3.0
        static let auxiliaryAnimationsDurationMultiplier = 3.0 / 4.0
        static let minAnimationsDuration = 0.25
        static let maxAnimationsDuration = 0.5
        static let failedGestureAnimationsDuration = 0.4

        static let defaultAnimationContext = OverlayContentContainerProgress.AnimationContext(
            duration: 0.5,
            curve: .easeOut,
            springDampingRatio: 0.85, // Natural damping for smooth bounce
            initialSpringVelocity: 0.3 // Smooth entry velocity, not too fast
        )
    }
}
