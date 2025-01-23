//
//  UITextInputSecurityHardeningConfigurator.swift
//  TangemUIUtils
//
//  Created by Andrey Fedorov on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public struct UITextInputSecurityHardeningConfigurator {
    private let isSecured: Bool

    public init(isSecured: Bool) {
        self.isSecured = isSecured
    }

    public func configure(_ instance: UITextInput) {
        // Manual casting and a lot of copy-paste due to an old longstanding Swift bug rdar://problem/15233922
        // see also https://github.com/swiftlang/swift/issues/48047 and https://github.com/swiftlang/swift/issues/51406
        switch instance {
        case let uiTextField as UITextField:
            uiTextField.isSecureTextEntry = isSecured
            uiTextField.textContentType = .dummyValue
            uiTextField.spellCheckingType = .no
            uiTextField.autocorrectionType = .no
            uiTextField.smartInsertDeleteType = .no
            uiTextField.smartDashesType = .no
            uiTextField.smartQuotesType = .no
            if #available(iOS 17.0, *) {
                uiTextField.inlinePredictionType = .no
            }
            if #available(iOS 18.0, *) {
                uiTextField.mathExpressionCompletionType = .no
                uiTextField.writingToolsBehavior = .none
            }
        case let uiTextView as UITextView:
            uiTextView.isSecureTextEntry = isSecured
            uiTextView.textContentType = .dummyValue
            uiTextView.spellCheckingType = .no
            uiTextView.autocorrectionType = .no
            uiTextView.smartInsertDeleteType = .no
            uiTextView.smartDashesType = .no
            uiTextView.smartQuotesType = .no
            if #available(iOS 17.0, *) {
                uiTextView.inlinePredictionType = .no
            }
            if #available(iOS 18.0, *) {
                uiTextView.mathExpressionCompletionType = .no
                uiTextView.writingToolsBehavior = .none
            }
        default:
            preconditionFailure("Unknown type received: '\(type(of: instance))'")
        }
    }
}

// MARK: - Convenience extensions

private extension UITextContentType {
    /// A dummy value since `.oneTimeCode` isn't always appropriate.
    static var dummyValue: Self { .init(rawValue: "") }
}
