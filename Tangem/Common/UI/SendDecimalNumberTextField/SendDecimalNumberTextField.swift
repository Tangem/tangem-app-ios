//
//  SendDecimalNumberTextField.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// Same as `DecimalNumberTextField` with  support
/// - `InitialFocusBehavior`
/// - `ToolbarType`
/// - `Suffix`
/// - Different `Alignment`
struct SendDecimalNumberTextField: View {
    // Public
    @ObservedObject private var viewModel: DecimalNumberTextField.ViewModel

    // Internal state
    @FocusState private var isInputActive: Bool
    @State private var textFieldText: String = ""
    @State private var measuredTextSize: CGSize = .zero

    // Setupable
    private var initialFocusBehavior: InitialFocusBehavior = .noFocus
    private var toolbarType: ToolbarType?
    private var appearance: DecimalNumberTextField.Appearance = .init()
    private var alignment: Alignment = .leading
    private var onFocusChanged: ((Bool) -> Void)?
    private var prefixSuffixOptions: PrefixSuffixOptions?

    private var textToMeasure: String {
        var text = ""

        if case .prefix(.some(let prefix), let hasSpace) = prefixSuffixOptions {
            text += makePrefixSuffixText(prefix, hasSpaceBeforeText: false, hasSpaceAfterText: hasSpace)
        }

        text += (textFieldText.nilIfEmpty ?? Constants.placeholder)

        if case .suffix(.some(let suffix), let hasSpace) = prefixSuffixOptions {
            text += makePrefixSuffixText(suffix, hasSpaceBeforeText: hasSpace, hasSpaceAfterText: false)
        }

        return text
    }

    private var prefixSuffixColor: Color {
        switch viewModel.value {
        case .none:
            return appearance.placeholderColor
        case .some:
            return appearance.textColor
        }
    }

    init(viewModel: DecimalNumberTextField.ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: alignment) {
                let maxWidth = proxy.size.width
                let textScale = clamp(maxWidth / measuredTextSize.width, min: Constants.minTextScale, max: Constants.maxTextScale)

                HStack(alignment: .center, spacing: 0) {
                    if case .prefix(.some(let prefix), let hasSpace) = prefixSuffixOptions {
                        prefixSuffixView(prefix, hasSpaceAfterText: hasSpace)
                    }

                    textField

                    if case .suffix(.some(let suffix), let hasSpace) = prefixSuffixOptions {
                        prefixSuffixView(suffix, hasSpaceBeforeText: hasSpace)
                    }
                }
                .frame(width: ceil(maxWidth / textScale), alignment: alignment)
                .scaleEffect(.init(bothDimensions: textScale))

                // Expand the tappable area
                Color.clear
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputActive = true
                    }
            }
            .lineLimit(1)
            .infinityFrame() // Provides centered alignment within `GeometryReader`
            .overlay(textSizeMeasurer)
        }
        .frame(height: measuredTextSize.height)
    }

    /// A dummy invisible view that is used to calculate the ideal (unlimited) width for a single-line input string.
    ///
    /// Other approaches have some issues and disadvantages:
    /// 1. `NSAttributedString.boundingRect(with:options:context:)` and `CTFramesetterSuggestFrameSizeWithConstraints(_:_:_:_:_:)`
    /// don't work correctly if the string contains spaces
    /// 2. `NSLayoutManager.usedRect(for:)` works just fine, but it doesn't support SwiftUI attributes for `NSAttributedString`
    /// (including the most important one, `font`), and these attributes must be converted to their UIKit counterparts.
    /// Which is very finicky and fragile since it uses runtime reflection, see https://movingparts.io/fonts-in-swiftui
    /// and https://github.com/LeoNatan/LNSwiftUIUtils for example.
    @ViewBuilder
    private var textSizeMeasurer: some View {
        Text(textToMeasure)
            .font(appearance.font)
            .lineLimit(1)
            .fixedSize()
            .hidden(true) // Native `.hidden()` may affect layout
            .readGeometry(\.size, bindTo: $measuredTextSize)
    }

    @ViewBuilder
    private var textField: some View {
        DecimalNumberTextField(viewModel: viewModel, textFieldText: $textFieldText)
            .appearance(appearance)
            .placeholder(Constants.placeholder)
            .focused($isInputActive)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    leadingToolbarView

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
                guard
                    !isInputActive,
                    let focusDelayDuration = initialFocusBehavior.delayDuration
                else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + focusDelayDuration) {
                    isInputActive = true
                }
            }
            .onChange(of: isInputActive) { isInputActive in
                onFocusChanged?(isInputActive)
            }
    }

    @ViewBuilder
    private var leadingToolbarView: some View {
        switch toolbarType {
        case .none:
            EmptyView()
        case .maxAmount(let action):
            Button(action: action) {
                Text(Localization.sendMaxAmountLabel)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)
            }
        }
    }

    @ViewBuilder
    private func prefixSuffixView(
        _ text: String,
        hasSpaceBeforeText: Bool = false,
        hasSpaceAfterText: Bool = false
    ) -> some View {
        Text(makePrefixSuffixText(text, hasSpaceBeforeText: hasSpaceBeforeText, hasSpaceAfterText: hasSpaceAfterText))
            .style(appearance.font, color: prefixSuffixColor)
            .onTapGesture {
                isInputActive = true
            }
    }

    private func makePrefixSuffixText(_ text: String, hasSpaceBeforeText: Bool, hasSpaceAfterText: Bool) -> String {
        var result = ""

        if hasSpaceBeforeText {
            result += Constants.spaceCharacter
        }

        result += text

        if hasSpaceAfterText {
            result += Constants.spaceCharacter
        }

        return result
    }
}

// MARK: - Setupable

extension SendDecimalNumberTextField: Setupable {
    func toolbarType(_ toolbarType: ToolbarType?) -> Self {
        map { $0.toolbarType = toolbarType }
    }

    func prefixSuffixOptions(_ prefixSuffixOptions: PrefixSuffixOptions) -> Self {
        map { $0.prefixSuffixOptions = prefixSuffixOptions }
    }

    func appearance(_ appearance: DecimalNumberTextField.Appearance) -> Self {
        map { $0.appearance = appearance }
    }

    func alignment(_ alignment: Alignment) -> Self {
        map { $0.alignment = alignment }
    }

    func initialFocusBehavior(_ initialFocusBehavior: InitialFocusBehavior) -> Self {
        map { $0.initialFocusBehavior = initialFocusBehavior }
    }

    func onFocusChanged(_ action: ((Bool) -> Void)?) -> Self {
        map { $0.onFocusChanged = action }
    }
}

extension SendDecimalNumberTextField {
    enum ToolbarType {
        case maxAmount(action: () -> Void)
    }

    enum InitialFocusBehavior {
        case noFocus
        case immediateFocus
        case delayedFocus(duration: TimeInterval)

        var delayDuration: TimeInterval? {
            switch self {
            case .noFocus:
                nil
            case .immediateFocus:
                0
            case .delayedFocus(let duration):
                duration
            }
        }
    }
}

// MARK: - Constants

private extension SendDecimalNumberTextField {
    enum Constants {
        static let spaceCharacter = " "
        static let placeholder = "0"
        static let minTextScale = 0.5
        static let maxTextScale = 1.0
    }
}

// MARK: - Previews

struct SendDecimalNumberTextField_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .prefixSuffixOptions(.suffix(text: "WEI", hasSpace: true))
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .prefixSuffixOptions(.suffix(text: "USDT", hasSpace: true))
                    .padding()
                    .background(Colors.Background.action)

                SendDecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
                    .prefixSuffixOptions(.suffix(text: "WEI", hasSpace: true))
                    .appearance(.init(font: Fonts.Regular.body))
                    .alignment(.leading)
                    .padding()
                    .background(Colors.Background.action)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}
