//
//  OnboardingSeedPhraseImportViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt
import TangemSdk

protocol SeedPhraseImportDelegate: AnyObject {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String?)
}

class OnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isSeedPhraseValid: Bool = false
    @Published var inputError: String? = nil
    @Published var suggestions: [String] = []
    @Published var errorAlert: AlertBinder? = nil
    @Published var passphrase: String = ""
    @Published var isPassphraseInputResponder: Bool? = nil
    @Published var passphraseBottomSheetModel: OnboardingSeedPassphraseInfoBottomSheetModel? = nil

    let inputProcessor: SeedPhraseInputProcessor
    weak var delegate: SeedPhraseImportDelegate?

    private var bag: Set<AnyCancellable> = []

    init(inputProcessor: SeedPhraseInputProcessor, delegate: SeedPhraseImportDelegate?) {
        self.inputProcessor = inputProcessor
        self.delegate = delegate
        bind()
    }

    deinit {
        AppLog.shared.debug("OnboardingSeedPhraseImportViewModel deinit")
    }

    func suggestionTapped(at index: Int) {
        inputProcessor.insertSuggestion(suggestions[index])
    }

    func onAppear() {
        UIScrollView.appearance().keyboardDismissMode = .none
    }

    func onDisappear() {
        UIScrollView.appearance().keyboardDismissMode = AppConstants.defaultScrollViewKeyboardDismissMode
    }

    func resetModel() {
        passphrase = ""
        inputError = nil
        isSeedPhraseValid = false
        suggestions = []
        isPassphraseInputResponder = nil
        passphraseBottomSheetModel = nil
    }

    func importSeedPhrase() {
        UIApplication.shared.endEditing()
        guard let validatedPhrase = inputProcessor.validatedSeedPhrase else {
            return
        }

        do {
            let mnemonic = try Mnemonic(with: validatedPhrase)
            Analytics.log(.onboardingSeedButtonImport)
            delegate?.importSeedPhrase(mnemonic: mnemonic, passphrase: passphrase)
        } catch {
            AppLog.shared.debug("[Seed Phrase] Failed to generate seed phrase using input. Error: \(error)")
            errorAlert = error.alertBinder
        }
    }

    func openPassphraseInfo() {
        let isPassphraseWasResponder = isPassphraseInputResponder
        isPassphraseInputResponder = nil
        passphraseBottomSheetModel = .init(actionHandler: { [weak self] in
            self?.passphraseBottomSheetModel = nil
            // We need to add small delay before reassign first responder to passphrase input
            // otherwise visual glitches with bottom sheet background will appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isPassphraseInputResponder = isPassphraseWasResponder
            }
        })
    }

    private func bind() {
        inputProcessor.isSeedPhraseValidPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSeedPhraseValid, on: self, ownership: .weak)
            .store(in: &bag)

        inputProcessor.$inputError
            .receive(on: DispatchQueue.main)
            .assign(to: \.inputError, on: self, ownership: .weak)
            .store(in: &bag)

        inputProcessor.$suggestions
            .receive(on: DispatchQueue.main)
            .assign(to: \.suggestions, on: self, ownership: .weak)
            .store(in: &bag)

        $isPassphraseInputResponder
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isPassphraseInputResponder in
                if isPassphraseInputResponder ?? false {
                    viewModel.suggestions = []
                }
            })
            .store(in: &bag)
    }
}
