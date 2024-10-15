//
//  SendDestinationViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import SwiftUI

class SendDestinationViewModel: ObservableObject, Identifiable {
    @Published var auxiliaryViewsVisible: Bool = true
    @Published var isEditMode: Bool = false

    @Published var addressViewModel: SendDestinationTextViewModel?
    @Published var additionalFieldViewModel: SendDestinationTextViewModel?

    @Published var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?
    @Published var showSuggestedDestinations = true

    let addressDescription: String
    let additionalFieldDescription: String

    var additionalFieldViewModelHasValue: Bool {
        additionalFieldViewModel?.text.isEmpty == false
    }

    // MARK: - Private

    private let settings: Settings
    private let interactor: SendDestinationInteractor
    private let sendQRCodeService: SendQRCodeService
    private let addressTextViewHeightModel: AddressTextViewHeightModel
    private weak var router: SendDestinationRoutable?

    private let suggestedWallets: [SendSuggestedDestinationWallet]
    private let _destinationText: CurrentValueSubject<String, Never> = .init("")
    private let _destinationAdditionalFieldText: CurrentValueSubject<String, Never> = .init("")
    private var bag: Set<AnyCancellable> = []

    weak var stepRouter: SendDestinationStepRoutable?

    // MARK: - Methods

    init(
        settings: Settings,
        interactor: SendDestinationInteractor,
        sendQRCodeService: SendQRCodeService,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) {
        self.settings = settings
        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.router = router

        addressDescription = Localization.sendRecipientAddressFooter(settings.networkName)
        additionalFieldDescription = Localization.sendRecipientMemoFooter

        suggestedWallets = settings.suggestedWallets.map { wallet in
            SendSuggestedDestinationWallet(name: wallet.name, address: wallet.address)
        }

        setupView()
        bind()
    }

    func scanQRCode() {
        let binding = Binding<String>(get: { "" }, set: { [weak self] value in
            self?.sendQRCodeService.qrCodeDidScanned(value: value)
        })
        router?.openQRScanner(with: binding, networkName: settings.networkName)
    }

    func onAppear() {
        auxiliaryViewsVisible = true
    }

    private func setupView() {
        addressViewModel = SendDestinationTextViewModel(
            style: .address,
            input: _destinationText.eraseToAnyPublisher(),
            isValidating: interactor.isValidatingDestination,
            isDisabled: .just(output: false),
            addressTextViewHeightModel: addressTextViewHeightModel,
            errorText: interactor.destinationError
        ) { [weak self] address in
            self?.interactor.update(destination: address, source: .textField)
        } didPasteDestination: { [weak self] address in
            self?._destinationText.send(address)
            // FIX ME: Call this method with source: .pasteButton to force the step changed
            self?.interactor.update(destination: address, source: .pasteButton)
        }

        additionalFieldViewModel = settings.additionalFieldType.map { additionalFieldType in
            SendDestinationTextViewModel(
                style: .additionalField(name: additionalFieldType.name),
                input: _destinationAdditionalFieldText.eraseToAnyPublisher(),
                isValidating: .just(output: false),
                isDisabled: interactor.canEmbedAdditionalField.map { !$0 }.eraseToAnyPublisher(),
                addressTextViewHeightModel: .init(),
                errorText: interactor.destinationAdditionalFieldError
            ) { [weak self] value in
                self?.interactor.update(additionalField: value)

            } didPasteDestination: { [weak self] value in
                self?._destinationAdditionalFieldText.send(value)
            }
        }
    }

    private func bind() {
        interactor
            .destinationValid
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destinationValid in
                self?.showSuggestedDestinations = !destinationValid
            }
            .store(in: &bag)

        interactor
            .transactionHistoryPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, recentTransactions in
                viewModel.setup(recentTransactions: recentTransactions)
            }
            .store(in: &bag)

        sendQRCodeService
            .qrCodeDestination
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, address in
                viewModel._destinationText.send(address)
            }
            .store(in: &bag)

        sendQRCodeService
            .qrCodeAdditionalField
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, field in
                viewModel._destinationAdditionalFieldText.send(field)
            }
            .store(in: &bag)

        interactor
            .canEmbedAdditionalField
            .filter { $0 == false }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, address in
                viewModel._destinationAdditionalFieldText.send("")
            }
            .store(in: &bag)
    }

    private func setup(recentTransactions: [SendSuggestedDestinationTransactionRecord]) {
        if suggestedWallets.isEmpty, recentTransactions.isEmpty {
            suggestedDestinationViewModel = nil
            return
        }

        suggestedDestinationViewModel = SendSuggestedDestinationViewModel(
            wallets: suggestedWallets,
            recentTransactions: recentTransactions
        ) { [weak self] destination in
            self?.userDidTapSuggestedDestination(destination)
        }
    }

    private func userDidTapSuggestedDestination(_ destination: SendSuggestedDestination) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        _destinationText.send(destination.address)
        interactor.update(destination: destination.address, source: destination.type.source)

        if let additionalField = destination.additionalField {
            _destinationAdditionalFieldText.send(additionalField)
        }

        guard !interactor.hasError else {
            return
        }

        // Give some time to update UI fields
        DispatchQueue.main.async {
            self.stepRouter?.destinationStepFulfilled()
        }
    }
}

// MARK: - SendStepViewAnimatable

extension SendDestinationViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.amount(_)):
            // Have to be always visible
            auxiliaryViewsVisible = true
            isEditMode = false
        case .appearing(.summary(_)):
            // Will be shown with animation
            auxiliaryViewsVisible = false
            isEditMode = true
        case .disappearing(.summary(_)):
            auxiliaryViewsVisible = false
            isEditMode = true
        default:
            break
        }
    }
}

extension SendDestinationViewModel {
    struct Settings {
        typealias SuggestedWallet = (name: String, address: String)

        let networkName: String
        let additionalFieldType: SendDestinationAdditionalFieldType?
        let suggestedWallets: [SuggestedWallet]
    }
}

private extension SendSuggestedDestination.DestinationType {
    var source: Analytics.DestinationAddressSource {
        switch self {
        case .otherWallet:
            return .myWallet
        case .recentAddress:
            return .recentAddress
        }
    }
}
