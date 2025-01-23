//
//  SeedPhraseTextView.swift
//  Tangem
//
//  Created by Andrew Son on 20/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemUIUtils

struct SeedPhraseTextView: UIViewRepresentable {
    private unowned var inputProcessor: SeedPhraseInputProcessor
    private let shouldBecomeFirstResponderAtStart: Bool

    init(inputProcessor: SeedPhraseInputProcessor, shouldBecomeFirstResponderAtStart: Bool) {
        self.inputProcessor = inputProcessor
        self.shouldBecomeFirstResponderAtStart = shouldBecomeFirstResponderAtStart
    }

    func makeUIView(context: UIViewRepresentableContext<SeedPhraseTextView>) -> UITextView {
        let textView = UITextView()

        // Security hardening settings
        let configurator = UITextInputSecurityHardeningConfigurator(isSecured: false)
        configurator.configure(textView)

        textView.backgroundColor = nil
        textView.autocapitalizationType = .none
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = false
        textView.enablesReturnKeyAutomatically = false
        textView.isEditable = true
        textView.returnKeyType = .next
        textView.textColor = inputProcessor.defaultTextColor
        textView.font = inputProcessor.defaultTextFont
        textView.keyboardType = .asciiCapable // We currently only support the BIP39 English word list
        context.coordinator.setupTextView(textView)

        var toolbarItems = [UIBarButtonItem]()
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

        if !toolbarItems.isEmpty {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            toolbar.items = toolbarItems
            toolbar.tintColor = UIColor.inputAccessoryViewTintColor
            textView.inputAccessoryView = toolbar
        }

        if shouldBecomeFirstResponderAtStart {
            textView.becomeFirstResponder()
        }

        return textView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(inputProcessor: inputProcessor)
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<SeedPhraseTextView>) {}
}

extension SeedPhraseTextView {
    class Coordinator: NSObject, UITextViewDelegate {
        var isUserTypingText = false
        var isInputValidated = false

        private weak var textView: UITextView?
        private unowned var inputProcessor: SeedPhraseInputProcessor

        private var textViewDidUpdateTextSubject = PassthroughSubject<Void, Never>()
        private var bag: Set<AnyCancellable> = []

        init(inputProcessor: SeedPhraseInputProcessor) {
            self.inputProcessor = inputProcessor
        }

        @objc
        func hideKeyboard() {
            UIApplication.shared.endEditing()
        }

        func setupTextView(_ textView: UITextView) {
            bag.removeAll()

            self.textView = textView

            // We can't use textView.publisher(\.text) because it was not implemented properly
            // so all changes are published only after editing ended.
            textViewDidUpdateTextSubject
                .debounce(for: 1, scheduler: DispatchQueue.main)
                .sink { [weak self] in
                    self?.validateInput()
                }
                .store(in: &bag)

            inputProcessor.suggestionToInsertPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] word, range in
                    self?.insertWord(word, in: range)
                }
                .store(in: &bag)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            validateInput()
            inputProcessor.clearSuggestions()
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            defer {
                textViewDidUpdateTextSubject.send(())
            }

            // If user typed or pasted something we can safely invalidate all previous results
            inputProcessor.resetValidation()

            let isNewLine = text.rangeOfCharacter(from: CharacterSet.newlines) != nil
            let text = isNewLine ? " " : text

            let oldText = textView.text ?? ""
            guard let oldTextRange = Range(range, in: oldText) else {
                return true
            }

            if text.count > 1 {
                // Prepare new copied text
                let preparedCopiedText = inputProcessor.prepare(copiedText: text)
                let newText = oldText.replacingCharacters(in: oldTextRange, with: " " + preparedCopiedText.string)
                let processedText = inputProcessor.validate(newInput: newText)

                // Calculating new caret position after pasting new text
                let newSelectedRange = NSRange(location: range.lowerBound + preparedCopiedText.string.count, length: 0)
                textView.attributedText = processedText

                textView.selectedRange = newSelectedRange
                // Because we updating text manually we need to update caret position and prevent inserting text by system
                return false
            }

            let oldCaretPosition = textView.selectedRange
            let newCaretPosition = NSRange(location: oldCaretPosition.location + (text.isEmpty ? -1 : text.count), length: 0)

            // If removing characters or if it is a letter we should check for suggestion
            // Text will be empty if user removes characters
            var needToClearSuggestions = true
            if text.isEmpty || (text.last?.isLetter ?? false) {
                // Save caret position and attributed text before inserting new character
                // to give system ability to manually replace characters and do validation
                // with debounce after text update.

                let oldAttributedText = textView.attributedText
                let textWithNewInput = textView.text.replacingCharacters(in: oldTextRange, with: text)

                textView.text = textWithNewInput
                textView.selectedRange = newCaretPosition

                if let currentTextRange = textView.selectedTextRange {
                    // We need to search in both directions from current caret position.
                    let leftSideWordRange = textView.tokenizer.rangeEnclosingPosition(currentTextRange.start, with: .word, inDirection: .storage(.backward))
                    let rightSideWordRange = textView.tokenizer.rangeEnclosingPosition(currentTextRange.start, with: .word, inDirection: .storage(.forward))

                    // If we have word on the left side, but doesn't have word on the right side
                    // we can provide suggestion for user.
                    // If we have word on right side this means that caret is locating
                    // either in the middle of the word or at the beginning of the word.
                    // In such cases we shouldn't provide suggestion for user.
                    if let leftSideWordRange, rightSideWordRange == nil, let word = textView.text(in: leftSideWordRange) {
                        needToClearSuggestions = false

                        let location = textView.offset(from: textView.beginningOfDocument, to: leftSideWordRange.start)
                        let length = textView.offset(from: leftSideWordRange.start, to: leftSideWordRange.end)
                        // This word range will be used to replace the text if user selects suggestion
                        let wordRange = NSRange(location: location, length: length)

                        inputProcessor.updateSuggestions(for: word, in: wordRange)
                    }
                }

                textView.attributedText = oldAttributedText
                textView.selectedRange = oldCaretPosition
            }

            if needToClearSuggestions {
                inputProcessor.clearSuggestions()
            }

            // We need to reset typing attributes after inserting space or erasing character, because all new input will
            // have same style as at the caret position.
            if text == " " || text.isEmpty {
                textView.typingAttributes = [
                    .foregroundColor: inputProcessor.defaultTextColor,
                    .font: inputProcessor.defaultTextFont,
                ]
            }

            // This need to prevent inserting new lines in text view and saving correct text coloring
            if isNewLine {
                let mutableAttrString = NSMutableAttributedString(attributedString: textView.attributedText)
                mutableAttrString.mutableString.replaceCharacters(in: range, with: text)
                textView.attributedText = mutableAttrString
                textView.selectedRange = newCaretPosition
                return false
            }

            return true
        }

        private func validateInput() {
            validateNewInput(textView?.text)
        }

        private func validateNewInput(_ newInput: String?) {
            guard let newInput, let textView = textView else {
                return
            }

            let validatedInput = inputProcessor.validate(newInput: newInput)
            let currentCaretPos = textView.selectedRange
            textView.attributedText = validatedInput
            textView.selectedRange = currentCaretPos
        }

        private func insertWord(_ word: String, in range: NSRange) {
            guard
                let textView = textView,
                let oldText = textView.text,
                let stringRange = Range(range, in: oldText)
            else {
                return
            }

            let newText = oldText.replacingCharacters(in: stringRange, with: word)
            let preparedText = inputProcessor.validate(newInput: newText)
            textView.attributedText = preparedText
            textView.selectedRange = NSRange(location: range.lowerBound + word.count + 1, length: 0)
        }
    }
}
