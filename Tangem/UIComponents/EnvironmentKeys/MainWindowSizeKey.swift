//
//  MainWindowSizeKey.swift
//  Tangem
//
//  Created by Andrew Son on 19/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

private struct MainWindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var mainWindowSize: CGSize {
        get { self[MainWindowSizeKey.self] }
        set { self[MainWindowSizeKey.self] = newValue }
    }
}
