//
//  Error+.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import SwiftUI
import TangemSdk
import TangemVisa

extension Error {
    var detailedError: Error {
        if case .underlying(let uError, _) = self as? MoyaError,
           case .sessionTaskFailed(let sessionError) = uError.asAFError {
            return sessionError
        }
        return self
    }

    var alertBinder: AlertBinder {
        toBindable().binder
    }

    private func toBindable() -> BindableError {
        self as? BindableError ?? BindableErrorWrapper(self)
    }
}

// MARK: - BindableErrorWrapper

private struct BindableErrorWrapper: BindableError {
    var binder: AlertBinder {
        return AlertBinder(alert: Alert(
            title: Text(Localization.commonError),
            message: Text(error.localizedDescription),
            dismissButton: Alert.Button.default(Text(Localization.commonOk))
        ))
    }

    private let error: Error

    init(_ error: Error) {
        self.error = error
    }
}

extension Error {
    var isCancellationError: Bool {
        switch self {
        case let moyaError as MoyaError:
            switch moyaError {
            case .underlying(let error, _):
                return error.asAFError?.isExplicitlyCancelledError ?? false
            default:
                return false
            }
        case is CancellationError:
            return true
        case let urlError as URLError:
            return urlError.code == URLError.Code.cancelled
        case let tangemSdkError as TangemSdkError:
            return tangemSdkError.isUserCancelled
        case let visaActivationError as VisaActivationError:
            if case .underlyingError(let error) = visaActivationError {
                if error is VisaActivationError {
                    return false
                }

                return error.isCancellationError
            }

            return false
        default:
            return false
        }
    }
}
