//
//  AlertFieldValidator.swift
//  Tangem
//
//  Created by Andrey Chukavin on 25.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

class AlertFieldValidator: NSObject {
    private let isValid: (String) -> Bool
    private var acceptButton: UIAlertAction?

    init(isValid: @escaping (String) -> Bool) {
        self.isValid = isValid
    }

    func setAcceptButton(_ acceptButton: UIAlertAction) {
        self.acceptButton = acceptButton
    }

    private func validateTextField(_ textField: UITextField) {
        let isValid = isValid(textField.text ?? "")

        textField.textColor = isValid ? nil : UIColor.textWarningColor
        acceptButton?.isEnabled = isValid
    }
}

extension AlertFieldValidator: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        validateTextField(textField)
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        validateTextField(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return isValid(textField.text ?? "")
    }
}

extension AlertFieldValidator {
    static func makeUniqueWalletNameFieldValidator(otherWalletNames: [String]) -> AlertFieldValidator {
        AlertFieldValidator { input in
            let input = input.trimmed()
            return !(otherWalletNames.contains(input) || input.isEmpty)
        }
    }
}
