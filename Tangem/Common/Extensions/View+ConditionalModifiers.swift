//
//  View+ConditionalModifiers.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Applies a modifier to a view
    ///
    /// - Parameters:
    ///   - content: The modifier to apply to the view.
    /// - Returns: The modified view.
    @ViewBuilder
    func modifyView<T: View>(@ViewBuilder content: (Self) -> T) -> some View {
        content(self)
    }

    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - condition: The condition to determine if the content should be applied.
    ///   - content: The modifier to apply to the view.
    /// - Returns: The modified view.
    @ViewBuilder
    func modifier<T: View>(
        if condition: @autoclosure () -> Bool,
        @ViewBuilder then content: (Self) -> T
    ) -> some View {
        if condition() {
            content(self)
        } else {
            self
        }
    }

    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - condition: The condition to determine the content to be applied.
    ///   - trueContent: The modifier to apply to the view if the condition passes.
    ///   - falseContent: The modifier to apply to the view if the condition fails.
    /// - Returns: The modified view.
    @ViewBuilder
    func modifier<TrueContent: View, FalseContent: View>(
        if condition: @autoclosure () -> Bool,
        @ViewBuilder then trueContent: (Self) -> TrueContent,
        @ViewBuilder else falseContent: (Self) -> FalseContent
    ) -> some View {
        if condition() {
            trueContent(self)
        } else {
            falseContent(self)
        }
    }

    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - ifLet: The optional value.
    ///   - content: The modifier to apply to the view in optionalValue is inwrapped.
    /// - Returns: The modified view.
    @ViewBuilder
    func modifier<Content: View, Value>(
        ifLet optionalValue: Value?,
        @ViewBuilder then content: (Self, Value) -> Content
    ) -> some View {
        if let optionalValue = optionalValue {
            content(self, optionalValue)
        } else {
            self
        }
    }
}
