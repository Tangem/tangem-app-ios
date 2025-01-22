//
//  SendDecimalNumberTextField.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

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

    // Setupable
    private var initialFocusBehavior: InitialFocusBehavior = .noFocus
    private var toolbarType: ToolbarType?
    private var appearance: DecimalNumberTextField.Appearance = .init()
    private var alignment: Alignment = .leading
    private var onFocusChanged: ((Bool) -> Void)?
    private var prefixSuffixOptions: PrefixSuffixOptions?
    private var minTextScale: CGFloat?

    private var textToMeasure: String {
        var text = ""

        if case .prefix(.some(let prefix), let hasSpace) = prefixSuffixOptions {
            text += makePrefixSuffixText(prefix, hasSpaceBeforeText: false, hasSpaceAfterText: hasSpace)
        }

        text += (viewModel.textFieldText.nilIfEmpty ?? Constants.placeholder)

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
        Group {
            // Disabling animations for the `viewModel.measuredTextSize` property to prevent
            // an unwanted animated transition from truncated text to the non-truncated one
            if #available(iOS 17.0, *) {
                content
                    .transaction(value: viewModel.measuredTextSize) { $0.animation = nil }
            } else {
                content
                    .animation(nil, value: viewModel.measuredTextSize)
            }
        }
        .frame(height: viewModel.measuredTextSize.height)
    }

    private var content: some View {
        GeometryReader { proxy in
            ZStack(alignment: alignment) {
                let (scale, width) = scaleAndWidth(using: proxy)
                HStack(alignment: .center, spacing: 0) {
                    if case .prefix(.some(let prefix), let hasSpace) = prefixSuffixOptions {
                        prefixSuffixView(prefix, hasSpaceAfterText: hasSpace)
                            .layoutPriority(1000.0)
                    }

                    textField

                    if case .suffix(.some(let suffix), let hasSpace) = prefixSuffixOptions {
                        prefixSuffixView(suffix, hasSpaceBeforeText: hasSpace)
                            .layoutPriority(1000.0)
                    }
                }
                .frame(width: width, alignment: alignment)
                .scaleEffect(.init(bothDimensions: scale))

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
        TextField(text: .constant(textToMeasure), label: EmptyView.init)
            .font(appearance.font)
            .lineLimit(1)
            .fixedSize()
            .hidden(true) // Native `.hidden()` may affect layout
            .allowsHitTesting(false)
            .readGeometry(\.size, bindTo: $viewModel.measuredTextSize)
    }

    @ViewBuilder
    private var textField: some View {
        DecimalNumberTextField(viewModel: viewModel)
            .appearance(appearance)
            .placeholder(Constants.placeholder)
            .focused($isInputActive)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    leadingToolbarView

                    Spacer()

                    Button {
                        isInputActive = false
                        // HACK
                        // Sometimes this toolbar can be showed on the sheet page
                        // Which was presented by view which uses this `TextField`
                        // Then we call `endEditing` to be sure that the keyboard will be closed
                        UIApplication.shared.endEditing()
                    } label: {
                        Assets.hideKeyboard.image
                            .renderingMode(.template)
                            .foregroundColor(Colors.Icon.primary1)
                    }
                }
            }
            .onAppear {
                switch initialFocusBehavior {
                case .noFocus:
                    break
                case .immediateFocus:
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

    private func scaleAndWidth(using proxy: GeometryProxy) -> (scale: CGFloat, width: CGFloat) {
        let maxWidth = proxy.size.width
        let measuredWidth = viewModel.measuredTextSize.width

        guard
            let minTextScale,
            measuredWidth > maxWidth
        else {
            // Apparently, SwiftUI structural identity changes when the scale of the view changes from 1.0 (no scaling)
            // to any other value and vice versa, from any other value back to back to 1.0 (no scaling).
            // This change of SwiftUI structural identity causes a reset of some of the view's internal state
            // (including `@Focused` properties), which in turn causes the active first responder to resign, i.e. hide the keyboard.
            //
            // The workaround here prevents this by placing the view into a `scaled` state, even if text scaling
            // is not actually needed at the moment. This scaled state should not affect view dimensions at all, because
            // it mimics the absence of scaling (by increasing the scale by 1% and decreasing the width by the same value, 1%)
            let onePercent = 0.01
            let multiplierBase = 1.0
            let defaultScaleMultiplier = multiplierBase + onePercent
            let defaultWidthMultiplier = multiplierBase - onePercent

            return (1.0 * defaultScaleMultiplier, maxWidth * defaultWidthMultiplier)
        }

        // It turns out that in some cases, HStack inserts some space (1pt) between neighboring child views,
        // despite its spacing being set to zero. This value is used to mitigate this behavior when we have two views
        // in the HStack (i.e., when we have either prefix or a suffix).
        let additionalWidth = prefixSuffixOptions != nil ? 1.0 : 0.0
        let totalWidth = measuredWidth + additionalWidth
        let scale = clamp(maxWidth / totalWidth, min: minTextScale, max: Constants.maxTextScale)
        let width = ceil(maxWidth / scale)

        return (scale, width)
    }
}

// MARK: - Setupable

extension SendDecimalNumberTextField: Setupable {
    func toolbarType(_ toolbarType: ToolbarType?) -> Self {
        map { $0.toolbarType = toolbarType }
    }

    func prefixSuffixOptions(_ prefixSuffixOptions: PrefixSuffixOptions?) -> Self {
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

    /// The scale factor that determines the smallest font size to use during drawing (custom implementation).
    /// - minTextScale: The desired `minimumScaleFactor` for custom font scaling. If nil, no font scaling applies.
    func minTextScale(_ minTextScale: CGFloat?) -> Self {
        map { $0.minTextScale = minTextScale }
    }
}

extension SendDecimalNumberTextField {
    enum ToolbarType {
        case maxAmount(action: () -> Void)
    }

    enum InitialFocusBehavior {
        case noFocus
        case immediateFocus
    }
}

// MARK: - Constants

private extension SendDecimalNumberTextField {
    enum Constants {
        static let spaceCharacter = " "
        static let placeholder = "0"
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
