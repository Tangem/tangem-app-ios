//
//  InternalLogger.swift
//  TangemVisa
//
//  Created by Andrew Son on 22/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

struct InternalLogger {
    func error(error: Error) {
        Logger.error(.visa, error)
    }

    func debug<T>(subsystem: Subsystem, _ message: @autoclosure () -> T) {
        Logger.error(.visa, subsystem, message())
    }
}

extension InternalLogger {
    enum Subsystem: String {
        case bridgeInteractorBuilder = "[Visa] [Bridge Interactor Builder]:\n"
        case bridgeInteractor = "[Visa] [Bridge Interactor]:\n"
        case apiService = "[Visa] [API Service]\n"
        case tokenInfoLoader = "[Visa] [TokenInfoLoader]:\n"
        case authorizationTokenHandler = "[Visa] [AuthorizationTokenHandler]: "
        case activationManager = "[Visa] [ActivationManager]: "
        case cardSetupHandler = "[Visa] [CardSetupHandler]: "
        case cardActivationOrderProvider = "[Visa] [CommonCardActivationOrderProvider]: "
        case cardAuthorizationProcessor = "[Visa] [CardAuthorizationProcessor]: "
        case cardActivationTask = "[Visa] [CardActivationTask]: "
    }
}
