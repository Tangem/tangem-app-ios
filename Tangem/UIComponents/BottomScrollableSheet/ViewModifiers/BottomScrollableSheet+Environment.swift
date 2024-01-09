//
//  BottomScrollableSheet+Environment.swift
//  Tangem
//
//  Created by Andrey Fedorov on 01.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

extension View {
    func onBottomScrollableSheetStateChange(
        _ observer: @escaping BottomScrollableSheetStateObserver
    ) -> some View {
        return environment(\.bottomScrollableSheetStateObserver, observer)
    }

    func bottomScrollableSheetConfiguration(
        isHiddenWhenCollapsed: Bool = BottomScrollableSheetConfigurationEnvironmentKey.defaultValue.isHiddenWhenCollapsed,
        prefersGrabberVisible: Bool = BottomScrollableSheetConfigurationEnvironmentKey.defaultValue.prefersGrabberVisible,
        allowsHitTesting: Bool = BottomScrollableSheetConfigurationEnvironmentKey.defaultValue.allowsHitTesting
    ) -> some View {
        let configuration = BottomScrollableSheetConfiguration(
            isHiddenWhenCollapsed: isHiddenWhenCollapsed,
            prefersGrabberVisible: prefersGrabberVisible,
            allowsHitTesting: allowsHitTesting
        )
        return environment(\.bottomScrollableSheetConfiguration, configuration)
    }
}

extension EnvironmentValues {
    var bottomScrollableSheetStateObserver: BottomScrollableSheetStateObserver? {
        get { self[BottomScrollableSheetStateObserverEnvironmentKey.self] }
        set { self[BottomScrollableSheetStateObserverEnvironmentKey.self] = newValue }
    }

    var bottomScrollableSheetConfiguration: BottomScrollableSheetConfiguration {
        get { self[BottomScrollableSheetConfigurationEnvironmentKey.self] }
        set { self[BottomScrollableSheetConfigurationEnvironmentKey.self] = newValue }
    }
}

// MARK: - Private implementation

private enum BottomScrollableSheetStateObserverEnvironmentKey: EnvironmentKey {
    static var defaultValue: BottomScrollableSheetStateObserver? { nil }
}

private enum BottomScrollableSheetConfigurationEnvironmentKey: EnvironmentKey {
    static let defaultValue = BottomScrollableSheetConfiguration(
        isHiddenWhenCollapsed: false,
        prefersGrabberVisible: true,
        allowsHitTesting: true
    )
}
