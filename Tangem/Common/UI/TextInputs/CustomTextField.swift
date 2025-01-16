//
//  CustomtextFiels.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomTextField: UIViewRepresentable {
    class Coordinator: NSObject, UITextFieldDelegate {
        typealias OnEditingChanged = (_ isResponder: Bool) -> Void
        typealias OnTextChanged = (_ text: String) -> Void

        var decimalCount: Int?
        var isEnabled = true

        private let actionButtonTapped: Binding<Bool>
        private let placeholder: String
        private let defaultStringToClear: String?
        private let maxCount: Int?
        private let onEditingChanged: OnEditingChanged
        private let onTextChanged: OnTextChanged

        init(
            actionButtonTapped: Binding<Bool>,
            placeholder: String,
            defaultStringToClear: String?,
            decimalCount: Int?,
            maxCount: Int?,
            onEditingChanged: @escaping OnEditingChanged,
            onTextChanged: @escaping OnTextChanged
        ) {
            self.actionButtonTapped = actionButtonTapped
            self.placeholder = placeholder
            self.defaultStringToClear = defaultStringToClear
            self.decimalCount = decimalCount
            self.maxCount = maxCount
            self.onEditingChanged = onEditingChanged
            self.onTextChanged = onTextChanged
        }

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            return isEnabled
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            onTextChanged(textField.text ?? "")
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            onEditingChanged(true)

            if let toClear = defaultStringToClear {
                if textField.text == toClear {
                    textField.text = ""
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            onEditingChanged(false)

            if let toClear = defaultStringToClear {
                if textField.text == "" {
                    textField.text = toClear
                }
            }
        }

        @objc
        func actionTapped() {
            actionButtonTapped.wrappedValue.toggle()
        }

        @objc
        func hideKeyboard() {
            UIApplication.shared.endEditing()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentString: NSString = textField.text! as NSString
            let newString: String =
                currentString.replacingCharacters(in: range, with: string) as String

            if let maxCount = maxCount, newString.count > maxCount {
                return false
            }

            guard let maxLength = decimalCount else {
                return true
            }

            guard Array(newString).filter({ $0 == "." || $0 == "," }).count <= 1 else {
                return false
            }

            var allowNew = true

            if let dotIndex = newString.firstIndex(of: ".") {
                let fromIndex = newString.index(after: dotIndex)
                let decimalsString = newString[fromIndex...]
                allowNew = decimalsString.count <= maxLength
            } else {
                allowNew = true
            }

            guard allowNew else {
                return false
            }

            if newString.contains(",") {
                textField.text = newString.replacingOccurrences(of: ",", with: ".")
                return false
            }

            return true
        }
    }

    @Binding var text: String
    @Binding var isResponder: Bool?
    @Binding var actionButtonTapped: Bool

    var isSecured: Bool = false
    var clearsOnBeginEditing: Bool = false
    var defaultStringToClear: String?
    var handleKeyboard: Bool = false
    var actionButton: String?
    var keyboard: UIKeyboardType = .default
    var clearButtonMode: UITextField.ViewMode = .never
    var textColor: UIColor = .tangemGrayDark4
    var font: UIFont = .systemFont(ofSize: 16.0)
    let placeholder: String
    let toolbarItems: [UIBarButtonItem]? = nil
    var decimalCount: Int?
    var isEnabled = true
    var maxCount: Int?
    var onPaste: () -> Void = {}

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = CustomUITextField(frame: .zero)
        textField.onPaste = onPaste
        textField.clearsOnBeginEditing = clearsOnBeginEditing
        textField.keyboardType = keyboard
        textField.font = font
        textField.textColor = textColor
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.clearButtonMode = clearButtonMode

        // Security hardening settings
        textField.isSecureTextEntry = isSecured
        textField.textContentType = .init(rawValue: "") // A dummy value since `.oneTimeCode` isn't appropriate here
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.smartInsertDeleteType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        if #available(iOS 17.0, *) {
            textField.inlinePredictionType = .no
        }
        if #available(iOS 18.0, *) {
            textField.mathExpressionCompletionType = .no
            textField.writingToolsBehavior = .none
        }

        var toolbarItems = [UIBarButtonItem]()
        if handleKeyboard {
            toolbarItems = [
                UIBarButtonItem(
                    barButtonSystemItem: .flexibleSpace,
                    target: nil,
                    action: nil
                ),
                UIBarButtonItem(
                    image: UIImage(systemName: "keyboard.chevron.compact.down"),
                    style: .plain,
                    target: context.coordinator,
                    action: #selector(context.coordinator.hideKeyboard)
                ),
            ]
        }

        if let actionButton = actionButton {
            toolbarItems.insert(
                UIBarButtonItem(
                    title: actionButton,
                    style: .plain,
                    target: context.coordinator,
                    action: #selector(context.coordinator.actionTapped)
                ),
                at: 0
            )
        }
        if !toolbarItems.isEmpty {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            toolbar.items = toolbarItems
            toolbar.tintColor = UIColor.inputAccessoryViewTintColor
            textField.inputAccessoryView = toolbar
        }

        return textField
    }

    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(
            actionButtonTapped: $actionButtonTapped,
            placeholder: placeholder,
            defaultStringToClear: defaultStringToClear,
            decimalCount: decimalCount,
            maxCount: maxCount,
            onEditingChanged: { isResponder in
                // This check prevents redundant setting of the variable, which could
                // lead to `publishing changes during view update` SwiftUI warning
                if self.isResponder != isResponder {
                    self.isResponder = isResponder
                }
            },
            onTextChanged: { text in
                // This check prevents redundant setting of the variable, which could
                // lead to `publishing changes during view update` SwiftUI warning
                if self.text != text {
                    self.text = text
                }
            }
        )
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        uiView.text = text
        uiView.textColor = textColor
        context.coordinator.decimalCount = decimalCount
        context.coordinator.isEnabled = isEnabled

        if isResponder ?? false {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }
}

private class CustomUITextField: UITextField {
    var onPaste: () -> Void = {}

    override func paste(_ sender: Any?) {
        onPaste()
        super.paste(sender)
    }
}
