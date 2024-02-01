//
//  FocusedDecimalNumberTextField.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// It same as`DecimalNumberTextField` but with support focus state / toolbar buttons / suffix
@available(iOS 15.0, *)
struct FocusedDecimalNumberTextField<ToolbarButton: View>: View {
    @Binding private var decimalValue: DecimalNumberTextField.DecimalValue?
    @FocusState private var isInputActive: Bool
    private let toolbarButton: () -> ToolbarButton

    private var maximumFractionDigits: Int
    private var placeholderColor: Color = Colors.Text.disabled
    private var textColor: Color = Colors.Text.primary1
    private var font: Font = Fonts.Regular.title1
    private var suffix: String? = nil
    private var suffixColor: Color {
        switch decimalValue {
        case .none:
            return placeholderColor
        case .some:
            return textColor
        }
    }

    init(
        decimalValue: Binding<DecimalNumberTextField.DecimalValue?>,
        maximumFractionDigits: Int,
        @ViewBuilder toolbarButton: @escaping () -> ToolbarButton
    ) {
        _decimalValue = decimalValue
        self.maximumFractionDigits = maximumFractionDigits
        self.toolbarButton = toolbarButton
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            textField

            if let suffix {
                Text(suffix)
                    .style(font, color: suffixColor)
                    .onTapGesture {
                        isInputActive = true
                    }
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var textField: some View {
        DecimalNumberTextField(
            decimalValue: $decimalValue,
            decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits)
        )
        .maximumFractionDigits(maximumFractionDigits)
        .font(font)
        .focused($isInputActive)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                toolbarButton()

                Spacer()

                Button {
                    isInputActive = false
                } label: {
                    Assets.hideKeyboard.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.primary1)
                }
            }
        }
        .onAppear {
            isInputActive = true
        }
    }
}

// MARK: - Setupable

@available(iOS 15.0, *)
extension FocusedDecimalNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }

    func font(_ font: Font) -> Self {
        map { $0.font = font }
    }

    func suffix(_ suffix: String?) -> Self {
        map { $0.suffix = suffix }
    }
}

@available(iOS 15.0, *)
struct FocusedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        StatefulPreviewWrapper(decimalValue) { decimalValue in
            FocusedDecimalNumberTextField(decimalValue: decimalValue, maximumFractionDigits: 8) {}
        }
        .padding()
        .border(Color.purple)
    }
}
