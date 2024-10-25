//
//  OverlayContentContainer+Environment.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Environment values

extension EnvironmentValues {
    var overlayContentContainer: OverlayContentContainer {
        get { self[OverlayContentContainerEnvironmentKey.self] }
        set { self[OverlayContentContainerEnvironmentKey.self] = newValue }
    }

    var overlayContentStateObserver: OverlayContentStateObserver {
        get { self[OverlayContentStateObserverEnvironmentKey.self] }
        set { self[OverlayContentStateObserverEnvironmentKey.self] = newValue }
    }

    var overlayContentStateController: OverlayContentStateController {
        get { self[OverlayContentStateControllerEnvironmentKey.self] }
        set { self[OverlayContentStateControllerEnvironmentKey.self] = newValue }
    }
}

// MARK: - Private implementation

private enum OverlayContentContainerEnvironmentKey: EnvironmentKey {
    static var defaultValue: OverlayContentContainer {
        return DummyOverlayContentContainerViewControllerAdapter()
    }
}

private enum OverlayContentStateObserverEnvironmentKey: EnvironmentKey {
    static var defaultValue: OverlayContentStateObserver {
        return DummyOverlayContentContainerViewControllerAdapter()
    }
}

private enum OverlayContentStateControllerEnvironmentKey: EnvironmentKey {
    static var defaultValue: OverlayContentStateController {
        return DummyOverlayContentContainerViewControllerAdapter()
    }
}

private struct DummyOverlayContentContainerViewControllerAdapter:
    OverlayContentContainer,
    OverlayContentStateObserver,
    OverlayContentStateController {
    var cornerRadius: CGFloat {
        assertIfNeeded(for: OverlayContentContainer.self)
        return .zero
    }

    var isScrollViewLocked: Bool {
        assertIfNeeded(for: OverlayContentContainer.self)
        return false
    }

    func installOverlay(_ overlayView: some View) {
        assertIfNeeded(for: OverlayContentContainer.self)
    }

    func removeOverlay() {
        assertIfNeeded(for: OverlayContentContainer.self)
    }

    func setOverlayHidden(_ isHidden: Bool) {
        assertIfNeeded(for: OverlayContentContainer.self)
    }

    func addObserver(_ observer: @escaping OverlayContentStateObserver.StateObserver, forToken token: any Hashable) {
        assertIfNeeded(for: OverlayContentStateObserver.self)
    }

    func addObserver(_ observer: @escaping OverlayContentStateObserver.ProgressObserver, forToken token: any Hashable) {
        assertIfNeeded(for: OverlayContentStateObserver.self)
    }

    func removeObserver(forToken token: any Hashable) {
        assertIfNeeded(for: OverlayContentStateObserver.self)
    }

    func collapse() {
        assertIfNeeded(for: OverlayContentStateController.self)
    }

    func expand() {
        assertIfNeeded(for: OverlayContentStateController.self)
    }

    private func assertIfNeeded<T>(for type: T) {
        assertionFailure("Inject proper `\(type)` implementation into the view hierarchy")
    }
}
