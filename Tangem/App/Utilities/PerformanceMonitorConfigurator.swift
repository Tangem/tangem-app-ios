//
//  PerformanceMonitorConfigurator.swift
//  Tangem
//
//  Created by Andrey Fedorov on 01.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

#if ALPHA || BETA || DEBUG
import GDPerformanceView_Swift
#endif // ALPHA || BETA || DEBUG

enum PerformanceMonitorConfigurator {
    #if ALPHA || BETA || DEBUG
    private static var performanceMonitorStyle: PerformanceMonitor.Style {
        return .custom(
            backgroundColor: UIColor.systemBackground,
            borderColor: UIColor.label,
            borderWidth: 1.0,
            cornerRadius: 5.0,
            textColor: UIColor.label,
            font: UIFont.systemFont(ofSize: 8.0)
        )
    }

    private static var isEnabledUsingLaunchArguments: Bool {
        return UserDefaults.standard.bool(forKey: "com.tangem.PerformanceMonitorEnabled")
    }

    private static var isEnabledUsingFeatureToggle: Bool {
        return FeatureStorage.instance.isPerformanceMonitorEnabled
    }
    #endif // ALPHA || BETA || DEBUG

    static func configureIfAvailable() {
        #if ALPHA || BETA || DEBUG
        guard isEnabledUsingLaunchArguments || isEnabledUsingFeatureToggle else { return }

        PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance, .device, .system, .memory]
        PerformanceMonitor.shared().performanceViewConfigurator.style = performanceMonitorStyle
        PerformanceMonitor.shared().start()
        #endif // ALPHA || BETA || DEBUG
    }
}
