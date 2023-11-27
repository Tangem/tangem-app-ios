//
//  MainBottomSheetVisibility.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct MainBottomSheetVisibility {
    var isShown: Bool { isShownSubject.value }
    var isShownPublisher: some Publisher<Bool, Never> { isShownSubject }
    private let isShownSubject: CurrentValueSubject<Bool, Never> = .init(false)

    mutating func show() {
        isShownSubject.value = true
    }

    mutating func hide() {
        isShownSubject.value = false
    }
}

// MARK: - Dependency injection

private struct MainBottomSheetVisibilityKey: InjectionKey {
    static var currentValue = MainBottomSheetVisibility()
}

extension InjectedValues {
    var mainBottomSheetVisibility: MainBottomSheetVisibility {
        get { Self[MainBottomSheetVisibilityKey.self] }
        set { Self[MainBottomSheetVisibilityKey.self] = newValue }
    }
}
