//
//  SendError.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendError: Error, BindableError {
    private let title: String
    private let message: String
    private let error: Error

    private let openMailAction: (Error) -> Void

    init(title: String, message: String, error: Error, openMailAction: @escaping (Error) -> Void) {
        self.title = title
        self.message = message
        self.error = error
        self.openMailAction = openMailAction
    }

    var alertBinder: AlertBinder {
        let alert = Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .default(Text(Localization.alertButtonRequestSupport), action: { openMailAction(error) }),
            secondaryButton: .default(Text(Localization.commonCancel))
        )

        return AlertBinder(alert: alert)
    }
}
