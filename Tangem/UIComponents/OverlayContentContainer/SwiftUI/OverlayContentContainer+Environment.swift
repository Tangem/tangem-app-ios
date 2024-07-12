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
}

// MARK: - Private implementation

private enum OverlayContentContainerEnvironmentKey: EnvironmentKey {
    static var defaultValue: OverlayContentContainer {
        return DummyOverlayContentContainer()
    }
}

private struct DummyOverlayContentContainer: OverlayContentContainer {
    func installOverlay(_ overlayView: some View) {
        assertionFailure("Inject proper `OverlayContentContainer` implementation into the view hierarchy")
    }

    func removeOverlay() {
        assertionFailure("Inject proper `OverlayContentContainer` implementation into the view hierarchy")
    }
}
