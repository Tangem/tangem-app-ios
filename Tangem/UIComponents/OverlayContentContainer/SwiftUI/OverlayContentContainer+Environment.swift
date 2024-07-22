//
//  OverlayContentContainer+Environment.swift
//  Tangem
//
//  Created by m3g0byt3 on 12.07.2024.
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

private struct DummyOverlayContentContainerViewControllerAdapter: OverlayContentContainer, OverlayContentStateObserver {
    func installOverlay(_ overlayView: some View) {
        assertIfNeeded(for: OverlayContentContainer.self)
    }

    func removeOverlay() {
        assertIfNeeded(for: OverlayContentContainer.self)
    }

    func addObserver(_ observer: @escaping Observer, forToken token: any Hashable) {
        assertIfNeeded(for: OverlayContentStateObserver.self)
    }

    func removeObserver(forToken token: any Hashable) {
        assertIfNeeded(for: OverlayContentStateObserver.self)
    }

    private func assertIfNeeded<T>(for type: T) {
        if FeatureProvider.isAvailable(.markets) {
            assertionFailure("Inject proper `\(type)` implementation into the view hierarchy")
        }
    }
}
