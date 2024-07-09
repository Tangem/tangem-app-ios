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

class SendDestinationViewModel: ObservableObject {
    @Published var addressViewModel: SendDestinationTextViewModel?
    @Published var additionalFieldViewModel: SendDestinationTextViewModel?

    @Published var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false
    @Published var showSuggestedDestinations = true

    var didProperlyDisappear: Bool = false

    // MARK: - Private

    private let settings: Settings
    private let interactor: SendDestinationInteractor
    private let addressTextViewHeightModel: AddressTextViewHeightModel
    private let suggestedWallets: [SendSuggestedDestinationWallet]

    private let _destinationText: CurrentValueSubject<String, Never> = .init("")
    private let _destinationAdditionalFieldText: CurrentValueSubject<String, Never> = .init("")
    private var bag: Set<AnyCancellable> = []

    // MARK: - Methods

    init(
        settings: Settings,
        interactor: SendDestinationInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) {
        suggestedWallets = settings.suggestedWallets.map { wallet in
            SendSuggestedDestinationWallet(name: wallet.name, address: wallet.address)
        }

        self.settings = settings
        self.interactor = interactor
        self.addressTextViewHeightModel = addressTextViewHeightModel

        setupView()
        bind()
    }

    func setExternally(address: SendAddress?, additionalField: String?) {
        address.map { _destinationText.send($0.value) }
        additionalField.map { _destinationAdditionalFieldText.send($0) }
    }

    func onAppear() {
        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .address])
        } else {
            Analytics.log(.sendAddressScreenOpened)
        }
    }

    private func setupView() {
        addressViewModel = SendDestinationTextViewModel(
            style: .address(networkName: settings.networkName),
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
                isDisabled: .just(output: false),
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
            // HACK: making sure it doesn't interfere with textview's updates
            .delay(for: 0.01, scheduler: DispatchQueue.main)
            .sink { [weak self] destinationValid in
                self?.showSuggestedDestinations = !destinationValid
            }
            .store(in: &bag)

        interactor
            .transactionHistoryPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, recentTransactions in
                viewModel.setup(recentTransactions: recentTransactions)
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            self?._destinationText.send(destination.address)
            self?.interactor.update(destination: destination.address, source: destination.type.source)

            if let additionalField = destination.additionalField {
                self?._destinationAdditionalFieldText.send(additionalField)
            }
        }
    }
}

// MARK: - AuxiliaryViewAnimatable

extension SendDestinationViewModel: AuxiliaryViewAnimatable {}

extension SendDestinationViewModel {
    struct Settings {
        typealias SuggestedWallet = (name: String, address: String)

        let networkName: String
        let additionalFieldType: SendAdditionalFields?
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
