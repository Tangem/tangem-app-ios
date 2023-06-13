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
        @Binding var text: String
        @Binding var isResponder: Bool?
        @Binding var actionButtonTapped: Bool
        let placeholder: String
        var decimalCount: Int?
        let defaultStringToClear: String?
        var isEnabled = true
        var maxCount: Int?

        init(
            text: Binding<String>,
            placeholder: String,
            decimalCount: Int?,
            defaultStringToClear: String?,
            isResponder: Binding<Bool?>,
            actionButtonTapped: Binding<Bool>,
            maxCount: Int?
        ) {
            _text = text
            _isResponder = isResponder
            _actionButtonTapped = actionButtonTapped
            self.placeholder = placeholder
            self.decimalCount = decimalCount
            self.defaultStringToClear = defaultStringToClear
            self.maxCount = maxCount
        }

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            return isEnabled
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isResponder = true
            }

            if let toClear = defaultStringToClear {
                if textField.text == toClear {
                    textField.text = ""
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isResponder = false
            }

            if let toClear = defaultStringToClear {
                if textField.text == "" {
                    textField.text = toClear
                }
            }
        }

        @objc
        func actionTapped() {
            actionButtonTapped.toggle()
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

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.isSecureTextEntry = isSecured
        textField.clearsOnBeginEditing = clearsOnBeginEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = keyboard
        textField.font = font
        textField.textColor = textColor
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.clearButtonMode = clearButtonMode
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
            toolbar.backgroundColor = UIColor.tangemBgGray
            toolbar.tintColor = UIColor.black
            textField.inputAccessoryView = toolbar
        }

        return textField
    }

    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(
            text: $text,
            placeholder: placeholder,
            decimalCount: decimalCount,
            defaultStringToClear: defaultStringToClear,
            isResponder: $isResponder,
            actionButtonTapped: $actionButtonTapped,
            maxCount: maxCount
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
