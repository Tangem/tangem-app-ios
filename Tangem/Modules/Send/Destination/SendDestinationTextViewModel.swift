//
//  SendDestinationTextViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendDestinationTextViewModel: ObservableObject, Identifiable {
    let name: String
    let showAddressIcon: Bool
    let description: String
    let didEnterDestination: (String) -> Void
    let didPasteDestination: (String) -> Void

    @Published var isValidating: Bool = false
    @Published var input: String = ""
    @Published var placeholder: String = ""
    @Published var isDisabled: Bool = true
    @Published var errorText: String?

    var hasTextInClipboard = false

    var shouldShowPasteButton: Bool {
        input.isEmpty && !isDisabled
    }

    private var bag: Set<AnyCancellable> = []

    init(
        style: Style,
        input: AnyPublisher<String, Never>,
        isValidating: AnyPublisher<Bool, Never>,
        isDisabled: AnyPublisher<Bool, Never>,
        errorText: AnyPublisher<Error?, Never>,
        didEnterDestination: @escaping (String) -> Void,
        didPasteDestination: @escaping (String) -> Void
    ) {
        name = style.name
        showAddressIcon = style.showAddressIcon
        description = style.description
        self.didEnterDestination = didEnterDestination
        self.didPasteDestination = didPasteDestination
        placeholder = style.placeholder(isDisabled: self.isDisabled)

        bind(style: style, input: input, isValidating: isValidating, isDisabled: isDisabled, errorText: errorText)
    }

    private func bind(style: Style, input: AnyPublisher<String, Never>, isValidating: AnyPublisher<Bool, Never>, isDisabled: AnyPublisher<Bool, Never>, errorText: AnyPublisher<Error?, Never>) {
        input
            .sink { [weak self] text in
                guard self?.input != text else { return }
                self?.input = text
            }
            .store(in: &bag)

        self.$input
            .removeDuplicates()
            .sink { [weak self] in
                self?.didEnterDestination($0)
            }
            .store(in: &bag)

        isValidating
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.isValidating, on: self, ownership: .weak)
            .store(in: &bag)

        isDisabled
            .removeDuplicates()
            .sink { [weak self] isDisabled in
                self?.isDisabled = isDisabled
                self?.placeholder = style.placeholder(isDisabled: isDisabled)
            }
            .store(in: &bag)

        errorText
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.errorText, on: self, ownership: .weak)
            .store(in: &bag)

        if #unavailable(iOS 16.0) {
            NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
                .sink { [weak self] _ in
                    self?.updatePasteButton()
                }
                .store(in: &bag)

            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.onBecomingActive()
                }
                .store(in: &bag)

            updatePasteButton()
        }
    }

    func onAppear() {
        updatePasteButton()
    }

    func onBecomingActive() {
        updatePasteButton()
    }

    func didTapPasteButton(_ input: String) {
        provideButtonHapticFeedback()
        didPasteDestination(input)
    }

    func didTapLegacyPasteButton() {
        guard let input = UIPasteboard.general.string else {
            return
        }

        provideButtonHapticFeedback()
        didPasteDestination(input)
    }

    func clearInput() {
        input = ""
    }

    private func provideButtonHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func updatePasteButton() {
        if #unavailable(iOS 16.0) {
            hasTextInClipboard = UIPasteboard.general.hasStrings
        }
    }
}

// MARK: - Text style

extension SendDestinationTextViewModel {
    enum Style {
        case address(networkName: String)
        case additionalField(name: String)
    }
}

private extension SendDestinationTextViewModel.Style {
    var name: String {
        switch self {
        case .address:
            Localization.sendRecipient
        case .additionalField(let additionalFieldName):
            additionalFieldName
        }
    }

    var showAddressIcon: Bool {
        switch self {
        case .address:
            true
        case .additionalField:
            false
        }
    }

    var description: String {
        switch self {
        case .address(let networkName):
            Localization.sendRecipientAddressFooter(networkName)
        case .additionalField:
            Localization.sendRecipientMemoFooter
        }
    }

    func placeholder(isDisabled: Bool) -> String {
        switch self {
        case .address:
            return Localization.sendEnterAddressField
        case .additionalField:
            return isDisabled ? Localization.sendAdditionalFieldAlreadyIncluded : Localization.sendOptionalField
        }
    }
}
