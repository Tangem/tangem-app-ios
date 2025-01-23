//
//  CustomPasswordTextField.swift
//  Tangem
//
//  Created by Andrew Son on 22/03/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomPasswordTextField: View {
    let placeholder: String
    let color: Color
    var backgroundColor: Color = Colors.Field.primary

    var password: Binding<String>
    var shouldBecomeFirstResponder: Bool = true

    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = {}

    var body: some View {
        FocusableTextField(
            shouldBecomeFirstResponder: shouldBecomeFirstResponder,
            placeholder: placeholder,
            text: password,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        )
        .frame(height: 48)
        .transition(.opacity)
        .foregroundColor(color)
        .padding(.leading, 16)
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

private extension CustomPasswordTextField {
    enum Field: Hashable {
        case secure
    }

    struct FocusableTextField: View {
        let shouldBecomeFirstResponder: Bool
        let placeholder: String
        let text: Binding<String>
        var onEditingChanged: (Bool) -> Void = { _ in }
        var onCommit: () -> Void = {}

        @FocusState private var focusedField: Field?

        var body: some View {
            SecureField(
                placeholder,
                text: text,
                onCommit: onCommit
            )
            .focused($focusedField, equals: .secure)
            .textContentType(.oneTimeCode)
            .keyboardType(.asciiCapable)
            .onAppear(perform: onAppear)
        }

        private func onAppear() {
            if shouldBecomeFirstResponder {
                focusedField = .secure
            }
        }
    }
}
