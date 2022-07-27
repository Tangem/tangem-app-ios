//
//  BiometricAuthorizationUtils.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import LocalAuthentication

enum BiometricAuthorizationUtils {
    static func getBiometricState() -> BiometricState {
        let context = LAContext()
        var error: NSError?
        let canEvaluatePolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if context.biometryType == .none {
            return .notExist
        }
        
        if !canEvaluatePolicy {
            return .forbidden
        }
        
        return .available
    }
}

extension BiometricAuthorizationUtils {
    enum BiometricState {
        case notExist
        case forbidden
        case available
    }
}
