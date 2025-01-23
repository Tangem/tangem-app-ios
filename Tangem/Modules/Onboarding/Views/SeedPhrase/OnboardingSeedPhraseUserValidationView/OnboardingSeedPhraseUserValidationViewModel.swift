//
//  OnboardingSeedPhraseUserValidationViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 23/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnboardingSeedPhraseUserValidationViewModel: ObservableObject {
    struct ValidationInput {
        let secondWord: String
        let seventhWord: String
        let eleventhWord: String
        let createWalletAction: () -> Void
    }

    @Published var firstInputText = ""
    @Published var secondInputText = ""
    @Published var thirdInputText = ""
    @Published var firstInputHasError = false
    @Published var secondInputHasError = false
    @Published var thirdInputHasError = false

    @Published var isCreateWalletButtonEnabled = false

    private let input: ValidationInput
    private var bag: Set<AnyCancellable> = []

    init(validationInput: ValidationInput) {
        input = validationInput

        bind()
    }

    deinit {
        AppLog.shared.debug("OnboardingSeedPhraseUserValidationViewModel deinit")
    }

    func createWallet() {
        input.createWalletAction()
    }

    private func bind() {
        subscribeToInputUpdates(to: \.$firstInputText, errorKeyParh: \.firstInputHasError, targetWord: input.secondWord, on: self)
        subscribeToInputUpdates(to: \.$secondInputText, errorKeyParh: \.secondInputHasError, targetWord: input.seventhWord, on: self)
        subscribeToInputUpdates(to: \.$thirdInputText, errorKeyParh: \.thirdInputHasError, targetWord: input.eleventhWord, on: self)
    }

    private func subscribeToInputUpdates(
        to inputKeyPath: KeyPath<OnboardingSeedPhraseUserValidationViewModel, Published<String>.Publisher>,
        errorKeyParh: ReferenceWritableKeyPath<OnboardingSeedPhraseUserValidationViewModel, Bool>,
        targetWord: String,
        on root: OnboardingSeedPhraseUserValidationViewModel
    ) {
        root[keyPath: inputKeyPath]
            .dropFirst()
            .removeDuplicates()
            .map { [weak root] newText in
                root?[keyPath: errorKeyParh] = false
                return newText
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self, weak root] newText in
                if !newText.isEmpty,
                   newText != targetWord {
                    root?[keyPath: errorKeyParh] = true
                }

                self?.updateButtonState()
            }
            .store(in: &bag)
    }

    private func updateButtonState() {
        isCreateWalletButtonEnabled = firstInputText == input.secondWord &&
            secondInputText == input.seventhWord &&
            thirdInputText == input.eleventhWord
    }
}
