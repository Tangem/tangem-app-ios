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

extension Error {
    var detailedError: Error {
        if case .underlying(let uError, _) = self as? MoyaError,
           case .sessionTaskFailed(let sessionError) = uError.asAFError {
            return sessionError
        }
        return self
    }

    var alertBinder: AlertBinder {
        toBindable().alertBinder
    }

    var alertController: UIAlertController {
        toBindable().alertController
    }

    private func toBindable() -> BindableError {
        self as? BindableError ?? BindableErrorWrapper(self)
    }
}

// MARK: - BindableErrorWrapper

private struct BindableErrorWrapper: BindableError {
    private let error: Error

    init(_ error: Error) {
        self.error = error
    }
}

extension BindableErrorWrapper: Error {
    var localizedDescription: String { error.localizedDescription }
}

extension BindableErrorWrapper: LocalizedError {
    var errorDescription: String? { (error as? LocalizedError)?.errorDescription }

    var failureReason: String? { (error as? LocalizedError)?.failureReason }

    var recoverySuggestion: String? { (error as? LocalizedError)?.recoverySuggestion }

    var helpAnchor: String? { (error as? LocalizedError)?.helpAnchor }
}
