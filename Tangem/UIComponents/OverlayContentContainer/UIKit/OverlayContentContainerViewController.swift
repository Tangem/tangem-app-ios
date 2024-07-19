//
//  OverlayContentContainerViewController.swift
//  Tangem
//
//  Created by m3g0byt3 on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class OverlayContentContainerViewController: UIViewController {
    // MARK: - Dependencies

    private let contentViewController: UIViewController
    private let overlayCollapsedHeight: CGFloat
    private let overlayExpandedVerticalOffset: CGFloat
    private var overlayCollapsedVerticalOffset: CGFloat { screenBounds.height - overlayCollapsedHeight }

    // MARK: - Mutable state

    private var overlayViewController: UIViewController?
    private var panGestureStartLocation: CGPoint = .zero
    private var shouldIgnorePanGestureRecognizer = false
    private var scrollViewContentOffsetLocker: ScrollViewContentOffsetLocker?

    private var progress: CGFloat = .zero {
        didSet { onProgressChange(oldValue: oldValue, newValue: progress) }
    }

    // TODO: Andrey Fedorov - Check for leaks (IOS-7364)
    private var stateObservers: [AnyHashable: OverlayContentStateObserver.Observer] = [:]

    // MARK: - Read-only state

    private var screenBounds: CGRect {
        return UIScreen.main.bounds
    }

    private var adjustedContentOffset: CGPoint {
        return scrollViewContentOffsetLocker?.scrollView.adjustedContentOffset ?? .zero
    }

    private var isExpandedState: Bool {
        return abs(1.0 - progress) <= .ulpOfOne
    }

    private var isCollapsedState: Bool {
        return abs(progress) <= .ulpOfOne
    }

    /// I.e. either collapsed or expanded.
    private var isFinalState: Bool {
        return isExpandedState || isCollapsedState
    }

    // MARK: - IBOutlets/UI

    private var overlayViewTopAnchorConstraint: NSLayoutConstraint?
    private var backgroundShadowView: UIView?

    // MARK: - Initialization/Deinitialization

    /// - Note: All height/offset parameters (`overlayCollapsedHeight`, `overlayExpandedVerticalOffset`, etc)
    /// are relative to the main screen bounds (w/o safe area).
    init(
        contentViewController: UIViewController,
        overlayCollapsedHeight: CGFloat,
        overlayExpandedVerticalOffset: CGFloat
    ) {
        self.contentViewController = contentViewController
        self.overlayCollapsedHeight = overlayCollapsedHeight
        self.overlayExpandedVerticalOffset = overlayExpandedVerticalOffset
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "init(coder:) has not been implemented")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPanGestureRecognizer()
        setupContent()
        setupBackgroundShadowView()
        setupOverlayIfAvailable()
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

        let overlayView = overlayViewController.view!
        overlayView.removeFromSuperview()

        overlayViewController.removeFromParent()
        self.overlayViewController = nil
    }

    func addObserver(_ observer: @escaping OverlayContentStateObserver.Observer, forToken token: any Hashable) {
        stateObservers[AnyHashable(token)] = observer
    }

    func removeObserver(forToken token: any Hashable) {
        stateObservers.removeValue(forKey: AnyHashable(token))
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .black
    }

    /// - Note: The order in which this method is called matters. Must be called between `setupContent` and `setupOverlay`.
    private func setupBackgroundShadowView() {
        // TODO: Andrey Fedorov - Add support for dark mode (adjust content view contrast instead of using background shadow) (IOS-7364)
        let backgroundShadowView = UIView(frame: screenBounds)
        backgroundShadowView.backgroundColor = .black
        backgroundShadowView.alpha = Constants.minBackgroundShadowViewAlpha
        backgroundShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundShadowView.isUserInteractionEnabled = false
        view.addSubview(backgroundShadowView)
        self.backgroundShadowView = backgroundShadowView
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

        contentView.layer.cornerRadius = Constants.cornerRadius // TODO: Andrey Fedorov - Add animation for content view's corners (IOS-7364)
        contentView.layer.masksToBounds = true

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
        containerView.addSubview(overlayView)

        let overlayViewTopAnchorConstraint = overlayView
            .topAnchor
            .constraint(equalTo: containerView.topAnchor, constant: overlayCollapsedVerticalOffset)
        self.overlayViewTopAnchorConstraint = overlayViewTopAnchorConstraint

        NSLayoutConstraint.activate([
            overlayViewTopAnchorConstraint,
            overlayView.heightAnchor.constraint(equalToConstant: screenBounds.height - overlayExpandedVerticalOffset),
            overlayView.widthAnchor.constraint(equalToConstant: screenBounds.width),
        ])

        overlayView.layer.cornerRadius = Constants.cornerRadius
        overlayView.layer.masksToBounds = true

        overlayViewController.didMove(toParent: self)
    }

    private func setupPanGestureRecognizer() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    // MARK: - State update

    private func updateProgress() {
        let verticalOffset = overlayViewTopAnchorConstraint?.constant ?? .zero

        progress = clamp(
            (overlayCollapsedVerticalOffset - verticalOffset) / (overlayCollapsedVerticalOffset - overlayExpandedVerticalOffset),
            min: 0.0,
            max: 1.0
        )
    }

    private func updateContentScale() {
        let contentLayer = contentViewController.view.layer
        let invertedProgress = 1.0 - progress
        let scale = Constants.minContentViewScale
            + (Constants.maxContentViewScale - Constants.minContentViewScale) * invertedProgress

        if isFinalState {
            let keyPath = String(_sel: #selector(getter: CALayer.transform)) // TODO: Andrey Fedorov - Animations should take gesture speed into account (IOS-7364)
            let animation = CABasicAnimation(keyPath: keyPath)
            animation.duration = Constants.animationDuration
            contentLayer.add(animation, forKey: #function)
        }

        let transform: CGAffineTransform = .scaleTransform(
            for: contentLayer.bounds.size,
            scaledBy: .init(x: scale, y: scale),
            aroundAnchorPoint: .init(x: 0.0, y: 1.0), // Bottom left corner
            translationCoefficient: Constants.contentViewTranslationCoefficient
        )

        contentLayer.setAffineTransform(transform)
    }

    private func updateBackgroundShadowViewAlpha() {
        let alpha = Constants.minBackgroundShadowViewAlpha
            + (Constants.maxBackgroundShadowViewAlpha - Constants.minBackgroundShadowViewAlpha) * progress

        if isFinalState {
            UIView.animate(withDuration: Constants.animationDuration) { // TODO: Andrey Fedorov - Animations should take gesture speed into account (IOS-7364)
                self.backgroundShadowView?.alpha = alpha
            }
        } else {
            backgroundShadowView?.alpha = alpha
        }
    }

    private func notifyStateObserversIfNeeded() {
        for stateObserver in stateObservers.values {
            if isCollapsedState {
                stateObserver(.bottom)
            } else if isExpandedState {
                // TODO: Andrey Fedorov - Add support for `Trigger.tapGesture` (IOS-7364)
                stateObserver(.top(trigger: .dragGesture))
            } else {
                // No-op
            }
        }
    }

    private func reset() {
        panGestureStartLocation = .zero
        shouldIgnorePanGestureRecognizer = false
        scrollViewContentOffsetLocker = nil
    }

    // MARK: - Handlers

    private func onProgressChange(oldValue: CGFloat, newValue: CGFloat) {
        guard oldValue != newValue else {
            return
        }

        updateContentScale()
        updateBackgroundShadowViewAlpha()
        notifyStateObserversIfNeeded()
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .changed:
            onPanGestureChanged(gestureRecognizer)
        case .ended:
            onPanGestureEnded(gestureRecognizer)
        case .cancelled, .failed:
            reset()
        case .possible, .began, .recognized:
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
        case .up where isExpandedState:
            // Normal scrolling to the bottom of the scroll view content, pan gesture recognizer should be ignored
            // for the entire duration of the gesture (until end)
            shouldIgnorePanGestureRecognizer = true
            return
        case .up where isCollapsedState:
            // Expanding overlay using pan gesture, the scroll view content offset should remain intact,
            // so we lock it and then use default logic
            scrollViewContentOffsetLocker?.lock()
        case .down where adjustedContentOffset.y <= Constants.minAdjustedContentOffsetToLockScrollView:
            // Dismissing overlay using pan gesture, the scroll view content offset should remain intact,
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
        overlayViewTopAnchorConstraint?.constant += translation.y
        gestureRecognizer.setTranslation(.zero, in: nil)

        updateProgress()
    }

    func onPanGestureEnded(_ gestureRecognizer: UIPanGestureRecognizer) {
        defer {
            reset()
        }

        if shouldIgnorePanGestureRecognizer {
            return
        }

        // TODO: Andrey Fedorov - Tweak predicted location calculation if needed (IOS-7364))
        let translation = gestureRecognizer.predictedTranslation(in: nil, atDecelerationRate: .fast)
        let overlayOrigin = overlayViewController?.view.frame.origin ?? .zero
        let predictedOverlayOriginY = abs(overlayOrigin.y + translation.y)
        let finalOffset = predictedOverlayOriginY > screenBounds.height / 2.0
            ? overlayCollapsedVerticalOffset
            : overlayExpandedVerticalOffset

        overlayViewTopAnchorConstraint?.constant = finalOffset
        UIView.animate(withDuration: Constants.animationDuration) { // TODO: Andrey Fedorov - Animations should take gesture speed into account (IOS-7364)
            self.view.layoutIfNeeded()
        }

        updateProgress()
    }

    // MARK: - Helpers

    private func verticalDirection(for gestureRecognizer: UIPanGestureRecognizer) -> VerticalDirection? {
        let location = gestureRecognizer.location(in: nil)

        if panGestureStartLocation.y > location.y {
            return .up
        }

        if panGestureStartLocation.y < location.y {
            return .down
        }

        // Edge case (is it even possible?), unable to determine
        return nil
    }
}

// MARK: - UIGestureRecognizerDelegate protocol conformance

extension OverlayContentContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: nil)
        panGestureStartLocation = location

        // The gesture is completely disabled if no overlay view controller is set
        return overlayViewController?.view.frame.contains(location) ?? false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer, let scrollView = otherGestureRecognizer.view as? UIScrollView {
            scrollViewContentOffsetLocker = .make(for: scrollView)
        }

        return true
    }
}

// MARK: - Auxiliary types

private extension OverlayContentContainerViewController {
    private enum VerticalDirection {
        case up
        case down
    }
}

// MARK: - Constants

private extension OverlayContentContainerViewController {
    enum Constants {
        static let minContentViewScale = 0.95
        static let maxContentViewScale = 1.0
        static let minBackgroundShadowViewAlpha = 0.0
        static let maxBackgroundShadowViewAlpha = 0.5
        static let cornerRadius = 24.0
        static let animationDuration = 0.3
        static let contentViewTranslationCoefficient = 0.5
        static let minAdjustedContentOffsetToLockScrollView = 10.0
    }
}
