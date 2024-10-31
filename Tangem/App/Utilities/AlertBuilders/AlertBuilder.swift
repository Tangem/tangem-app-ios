//
//  AlertBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 20/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

enum AlertBuilder {
    static var successTitle: String {
        Localization.commonSuccess
    }

    static var warningTitle: String {
        Localization.commonWarning
    }

    static var okButtonTitle: String { Localization.commonOk }

    static func makeSuccessAlert(message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(successTitle),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)
        ))
    }

    static func makeSuccessAlertController(message: String, okAction: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: successTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction?() }))
        return alert
    }

    static func makeOkGotItAlert(message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(warningTitle),
            message: Text(message),
            dismissButton: .default(Text(Localization.warningButtonOk), action: okAction)
        ))
    }

    static func makeOkGotItAlertController(message: String, okAction: @escaping (() -> Void) = {}) -> UIAlertController {
        let alert = UIAlertController(title: warningTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction() }))
        return alert
    }

    static func makeOkErrorAlert(message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(Localization.commonError),
            message: Text(message),
            dismissButton: .default(Text(Localization.warningButtonOk), action: okAction)
        ))
    }

    static func makeDemoAlert(_ message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(warningTitle),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)
        ))
    }

    static func makeOldDeviceAlert() -> AlertBinder {
        .init(alert: Alert(
            title: Text(warningTitle),
            message: Text(Localization.onboardingAlertMessageOldDevice),
            dismissButton: .default(Text(Localization.commonOk), action: {})
        ))
    }

    static func makeExitAlert(okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(Localization.onboardingExitAlertTitle),
            message: Text(Localization.onboardingExitAlertMessage),
            primaryButton: .default(Text(Localization.commonNo), action: {}),
            secondaryButton: .destructive(Text(Localization.commonYes), action: okAction)
        ))
    }

    static func makeAlert(title: String, message: String, primaryButton: Alert.Button, secondaryButton: Alert.Button? = nil) -> AlertBinder {
        if let secondaryButton {
            return .init(alert: Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            ))
        } else {
            return .init(alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: primaryButton
            ))
        }
    }

    static func makeAlertControllerWithTextField(
        title: String,
        fieldPlaceholder: String,
        fieldText: String,
        autoCapitalize: Bool = true,
        useSpellCheck: Bool = true,
        fieldValidator: AlertFieldValidator? = nil,
        mapText: @escaping (String) -> String = { value in value },
        action: @escaping (String) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Localization.commonCancel, style: .cancel)
        alert.addAction(cancelAction)

        var nameTextField: UITextField?
        alert.addTextField { textField in
            nameTextField = textField
            nameTextField?.placeholder = fieldPlaceholder
            nameTextField?.text = fieldText
            nameTextField?.clearButtonMode = .whileEditing
            nameTextField?.autocapitalizationType = autoCapitalize ? .sentences : .none
            nameTextField?.spellCheckingType = useSpellCheck ? .default : .no
            nameTextField?.delegate = fieldValidator
        }

        let acceptButton = UIAlertAction(title: Localization.commonOk, style: .default) { [nameTextField] _ in
            withExtendedLifetime(fieldValidator) {}
            let text = nameTextField?.text ?? ""
            let mappedText = mapText(text)
            action(mappedText)
        }
        alert.addAction(acceptButton)

        fieldValidator?.setAcceptButton(acceptButton)

        return alert
    }

    static func makeWalletRenamingAlert(
        userWalletRepository: UserWalletRepository,
        updateName: ((String) -> Void)? = nil
    ) -> UIAlertController? {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return nil
        }

        let otherWalletNames = userWalletRepository.models.compactMap { model -> String? in
            guard model.userWalletId != userWalletModel.userWalletId else { return nil }
            return model.name
        }

        return AlertBuilder.makeAlertControllerWithTextField(
            title: Localization.userWalletListRenamePopupTitle,
            fieldPlaceholder: Localization.userWalletListRenamePopupPlaceholder,
            fieldText: userWalletModel.name,
            fieldValidator: AlertFieldValidator.makeUniqueWalletNameFieldValidator(otherWalletNames: otherWalletNames),
            mapText: { name in
                name.trimmed()
            },
            action: { newName in
                if userWalletModel.name != newName {
                    userWalletModel.updateWalletName(newName)
                    updateName?(newName)
                }
            }
        )
    }

    static func makeAlert(title: String, message: String, with buttons: Buttons) -> AlertBinder {
        .init(
            alert: .init(
                title: Text(title),
                message: Text(message),
                primaryButton: buttons.primaryButton,
                secondaryButton: buttons.secondaryButton
            )
        )
    }
}

extension AlertBuilder {
    struct Buttons {
        let primaryButton: Alert.Button
        let secondaryButton: Alert.Button

        init(primaryButton: Alert.Button, secondaryButton: Alert.Button) {
            self.primaryButton = primaryButton
            self.secondaryButton = secondaryButton
        }

        static func withPrimaryCancelButton(secondaryTitle: String, secondaryAction: @escaping () -> Void) -> Buttons {
            .init(
                primaryButton: .cancel(),
                secondaryButton: .default(Text(secondaryTitle), action: secondaryAction)
            )
        }
    }
}
