//
//  DecimalNumberTextField.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct DecimalNumberTextField: View {
    @ObservedObject private var viewModel: ViewModel

    // Setupable properties
    private var placeholder: String = "0"
    private var appearance: Appearance = .init()

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // A dummy invisible view that controls the layout (i.e. limits the max width) of `DecimalNumberTextField`
            Text(viewModel.textFieldText.isEmpty ? placeholder : viewModel.textFieldText)
                .font(appearance.font)
                .hidden(true)
                .layoutPriority(1)

            textField
        }
        .lineLimit(1)
    }

    private var textField: some View {
        TextField(text: $viewModel.textFieldText, prompt: prompt, label: {})
            .style(appearance.font, color: appearance.textColor)
            .tint(appearance.textColor)
            .labelsHidden()
            .keyboardType(.decimalPad)
            .onChange(of: viewModel.textFieldText) { newValue in
                updateValues(with: newValue)
            }
            .modifyView { view in
                // We have to check `initial` decimalValue when textField is appearing
                // On iOS 17 we have `initial: true` flag to support this behaviour
                // On previous iOS we use `onAppear` to handle this behaviour
                if #available(iOS 17.0, *) {
                    view
                        .onChange(of: viewModel.decimalValue, initial: true) { _, newDecimalValue in
                            updateValues(decimalValue: newDecimalValue)
                        }
                } else {
                    view
                        .onChange(of: viewModel.decimalValue) { newDecimalValue in
                            updateValues(decimalValue: newDecimalValue)
                        }
                        .onAppear {
                            updateValues(decimalValue: viewModel.decimalValue)
                        }
                }
            }
    }

    private var prompt: Text {
        Text(placeholder)
            // We can't use .style(font:, color:) here because
            // We should have the `Text` type
            .font(appearance.font)
            .foregroundColor(appearance.placeholderColor)
    }

    private func updateValues(decimalValue: ViewModel.DecimalValue?) {
        switch decimalValue {
        case .none, .internal:
            // Do nothing. Because all internal values already updated
            break
        case .external(let value):
            // If the decimalValue did updated from external place
            // We have to update the private values
            let formattedNewValue = viewModel.format(value: value)
            updateValues(with: formattedNewValue)
        }
    }

    private func updateValues(with newValue: String) {
        let decimalSeparator = viewModel.decimalSeparator()

        var numberString = newValue

        if viewModel.isDecimal() {
            // If user start enter number with `decimalSeparator` add zero before it
            if numberString == String(decimalSeparator) {
                numberString.insert("0", at: numberString.startIndex)
            }

            // If user double tap on zero, add `decimalSeparator` to continue enter number
            if numberString == "00" {
                numberString.insert(decimalSeparator, at: numberString.index(before: numberString.endIndex))
            }

            // If text already have `decimalSeparator` remove last one
            if numberString.last == decimalSeparator,
               numberString.prefix(numberString.count - 1).contains(decimalSeparator) {
                numberString.removeLast()
            }
        }

        // Format the string and reduce the tail
        numberString = viewModel.format(value: numberString)

        // Update private `@State` for display not correct number, like 0,000
        viewModel.textFieldText = numberString

        if let value = viewModel.mapToDecimal(string: numberString) {
            viewModel.update(decimalValue: .internal(value))
        } else if numberString.isEmpty {
            viewModel.update(decimalValue: nil)
        }
    }
}

// MARK: - Setupable

extension DecimalNumberTextField: Setupable {
    func placeholder(_ placeholder: String) -> Self {
        map { $0.placeholder = placeholder }
    }

    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }
}

struct DecimalNumberTextField_Previews: PreviewProvider {
    static var previews: some View {
        DecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
    }
}

// MARK: - ViewModel

extension DecimalNumberTextField {
    class ViewModel: ObservableObject {
        @Published var textFieldText: String = ""
        @Published var measuredTextSize: CGSize = .zero

        // Public properties
        var value: Decimal? {
            decimalValue?.value
        }

        var valuePublisher: AnyPublisher<Decimal?, Never> {
            $decimalValue
                .removeDuplicates { $0?.value == $1?.value }
                // We skip the first nil value from the text field
                .dropFirst()
                // If value == nil then continue chain to reset states to idle
                .filter { $0 == nil || $0?.isInternal == true }
                .map { $0?.value }
                .eraseToAnyPublisher()
        }

        var debouncedValuePublisher: AnyPublisher<Decimal?, Never> {
            valuePublisher
                .flatMapLatest { value in
                    if value == nil {
                        // Nil value will be emitted without debounce
                        return Just(value).eraseToAnyPublisher()
                    }

                    // But if have the value we will wait a bit
                    return Just(value)
                        .delay(for: 1, scheduler: DispatchQueue.global())
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        // Fileprivate
        @Published fileprivate var decimalValue: DecimalValue?

        // Private
        private let decimalNumberFormatter: DecimalNumberFormatter

        init(maximumFractionDigits: Int) {
            decimalNumberFormatter = .init(maximumFractionDigits: maximumFractionDigits)
        }

        // MARK: - Public

        func update(maximumFractionDigits: Int) {
            decimalNumberFormatter.update(maximumFractionDigits: maximumFractionDigits)
        }

        /// Use this method for `external` update the `decimalValue`
        func update(value: Decimal?) {
            guard let value else {
                decimalValue = nil
                return
            }

            decimalValue = .external(value)
        }

        // MARK: - Fileprivate only for DecimalNumberTextField

        fileprivate func isDecimal() -> Bool {
            decimalNumberFormatter.isDecimal
        }

        fileprivate func decimalSeparator() -> Character {
            decimalNumberFormatter.decimalSeparator
        }

        fileprivate func format(value: String) -> String {
            decimalNumberFormatter.format(value: value)
        }

        fileprivate func format(value: Decimal) -> String {
            decimalNumberFormatter.format(value: value)
        }

        fileprivate func mapToDecimal(string: String) -> Decimal? {
            decimalNumberFormatter.mapToDecimal(string: string)
        }

        fileprivate func update(decimalValue value: DecimalValue?) {
            guard let value else {
                decimalValue = nil
                return
            }

            decimalValue = value
        }
    }
}

// MARK: - Appearance

extension DecimalNumberTextField {
    struct Appearance {
        let font: Font
        let textColor: Color
        let placeholderColor: Color

        init(
            font: Font = Fonts.Regular.title1,
            textColor: Color = Colors.Text.primary1,
            placeholderColor: Color = Colors.Text.disabled
        ) {
            self.font = font
            self.textColor = textColor
            self.placeholderColor = placeholderColor
        }
    }
}

// MARK: - DecimalValue

private extension DecimalNumberTextField.ViewModel {
    enum DecimalValue: Hashable {
        case `internal`(Decimal)
        case external(Decimal)

        var value: Decimal {
            switch self {
            case .internal(let value):
                return value
            case .external(let value):
                return value
            }
        }

        var isInternal: Bool {
            switch self {
            case .internal:
                return true
            case .external:
                return false
            }
        }
    }
}
