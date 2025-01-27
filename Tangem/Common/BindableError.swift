//
//  BindableError.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TangemSdk

protocol BindableError {
    var binder: AlertBinder { get }
}

// MARK: - TangemSdkError + BindableError

extension TangemSdkError: BindableError {
    var binder: AlertBinder {
        switch self {
        case .cardVerificationFailed:
            Analytics.log(.errorOfflineAttestationFailed)

            return AlertBinder(alert: Alert(
                title: Text(Localization.securityAlertTitle),
                message: Text(TangemSdkError.cardVerificationFailed.localizedDescription),
                primaryButton: Alert.Button.default(Text(Localization.alertButtonRequestSupport), action: {
                    openSupport()
                }),
                secondaryButton: Alert.Button.cancel(Text(Localization.commonCancel))
            )
            )
        default:
            return AlertBinder(alert: Alert(
                title: Text(Localization.commonError),
                message: Text(localizedDescription),
                dismissButton: Alert.Button.default(Text(Localization.commonOk))
            ))
        }
    }

    private func openSupport() {
        let logsComposer = LogsComposer(infoProvider: BaseDataCollector())
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.default.recipient,
            emailType: .attestationFailed
        )
        let mailView = MailView(viewModel: mailViewModel)
        let controller = UIHostingController(rootView: mailView)
        AppPresenter.shared.show(controller)
    }
}

// MARK: UserWalletRepositoryError + BindableError

enum UserWalletRepositoryError: String, Error, LocalizedError, BindableError {
    case duplicateWalletAdded
    case biometricsChanged
    case cardWithWrongUserWalletIdScanned

    var errorDescription: String? {
        rawValue
    }

    var binder: AlertBinder {
        switch self {
        case .duplicateWalletAdded:
            return .init(title: "", message: Localization.userWalletListErrorWalletAlreadySaved)
        case .biometricsChanged:
            return .init(title: Localization.commonAttention, message: Localization.keyInvalidatedWarningDescription)
        case .cardWithWrongUserWalletIdScanned:
            return .init(title: Localization.commonWarning, message: Localization.errorWrongWalletTapped)
        }
    }
}
