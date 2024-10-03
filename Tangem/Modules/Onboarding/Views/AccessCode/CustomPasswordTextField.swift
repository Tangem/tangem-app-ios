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

    @State var isSecured: Bool = true

    @ViewBuilder
    var input: some View {
        FocusableTextField(
            isSecured: isSecured,
            shouldBecomeFirstResponder: shouldBecomeFirstResponder,
            placeholder: placeholder,
            text: password,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        )
    }

    var body: some View {
        GeometryReader { geom in
            HStack(spacing: 8) {
                input
                    .autocapitalization(.none)
                    .transition(.opacity)
                    .foregroundColor(color)
                    .keyboardType(.default)
                    .disableAutocorrection(true)

                Button(action: {
                    withAnimation {
                        isSecured.toggle()
                    }
                }, label: {
                    Image(systemName: isSecured ? "eye" : "eye.slash")
                        .foregroundColor(color)
                        .frame(width: geom.size.height, height: geom.size.height, alignment: .center)
                })
            }
            .padding(.leading, 16)
            .background(backgroundColor)
            .cornerRadius(10)
        }
    }
}

private extension CustomPasswordTextField {
    enum Field: Hashable {
        case secure
        case plain
    }

    struct FocusableTextField: View {
        let isSecured: Bool
        let shouldBecomeFirstResponder: Bool
        let placeholder: String
        let text: Binding<String>
        var onEditingChanged: (Bool) -> Void = { _ in }
        var onCommit: () -> Void = {}

        @FocusState private var focusedField: Field?

        var body: some View {
            ZStack {
                if isSecured {
                    SecureField(
                        placeholder,
                        text: text,
                        onCommit: onCommit
                    )
                    .focused($focusedField, equals: .secure)
                } else {
                    TextField(
                        placeholder,
                        text: text,
                        onEditingChanged: onEditingChanged,
                        onCommit: onCommit
                    )
                    .focused($focusedField, equals: .plain)
                }
            }
            .keyboardType(.default)
            .onAppear(perform: onAppear)
            .onChange(of: isSecured) { newValue in
                setFocus(for: newValue)
            }
        }

        private func setFocus(for value: Bool) {
            focusedField = value ? .secure : .plain
        }

        private func onAppear() {
            if shouldBecomeFirstResponder {
                setFocus(for: isSecured)
            }
        }
    }
}
