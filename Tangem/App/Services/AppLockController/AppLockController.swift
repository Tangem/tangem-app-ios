//
//  AppLockController.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

protocol AppLockController {
    var isLocked: Bool { get }

    func sceneDidEnterBackground()
    func sceneWillEnterForeground()

    func unlockApp(completion: @escaping (UnlockResult) -> Void)
}

enum UnlockResult {
    case openAuth
    case openWelcome
    case openMain(UserWalletModel)
}

private struct AppLockControllerKey: InjectionKey {
    static var currentValue: AppLockController = CommonAppLockController()
}

extension InjectedValues {
    var appLockController: AppLockController {
        get { Self[AppLockControllerKey.self] }
        set { Self[AppLockControllerKey.self] = newValue }
    }
}
