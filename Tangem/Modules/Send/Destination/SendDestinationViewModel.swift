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

protocol SendDestinationInput: AnyObject {}

protocol SendDestinationOutput: AnyObject {
    func destinationDidChanged(_ address: SendAddress?)
    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType)
}

class SendDestinationViewModel: ObservableObject {
    @Published var addressViewModel: SendDestinationTextViewModel?
    @Published var additionalFieldViewModel: SendDestinationTextViewModel?

    @Published var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false
    @Published var showSuggestedDestinations = true

    var didProperlyDisappear: Bool = false

    // MARK: - Private

    private let _destinationValid: CurrentValueSubject<Bool, Never> = .init(false)

    private let _destinationText: CurrentValueSubject<String, Never> = .init("")
    private let _isValidatingDestination: CurrentValueSubject<Bool, Never> = .init(false)
    private let _destinationError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let _destinationAdditionalFieldText: CurrentValueSubject<String, Never> = .init("")
    private let _canChangeAdditionalField: CurrentValueSubject<Bool, Never> = .init(true)
    private let _destinationAdditionalFieldError: CurrentValueSubject<Error?, Never> = .init(nil)

    private let initial: InitialModel
    private weak var input: SendDestinationInput?
    private weak var output: SendDestinationOutput?
    private let processor: SendDestinationProcessor

    private let addressTextViewHeightModel: AddressTextViewHeightModel
    private let transactionHistoryMapper: TransactionHistoryMapper
    private let suggestedWallets: [SendSuggestedDestinationWallet]
    private let transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never>

    private var bag: Set<AnyCancellable> = []

    // MARK: - Methods

    init(
        initial: InitialModel,
        input: SendDestinationInput,
        output: SendDestinationOutput,
        processor: SendDestinationProcessor,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        transactionHistoryMapper: TransactionHistoryMapper
    ) {
        suggestedWallets = initial.suggestedWallets.map { wallet in
            SendSuggestedDestinationWallet(name: wallet.name, address: wallet.address)
        }

        transactionHistoryPublisher = initial.transactionHistoryPublisher

        self.initial = initial
        self.input = input
        self.output = output
        self.processor = processor

        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.transactionHistoryMapper = transactionHistoryMapper

        setupView()
        bind()

        if let predefinedDestination = initial.predefinedDestination {
            _destinationText.send(predefinedDestination)
            destinationDidChange(address: predefinedDestination, source: .sellProvider)
        }

        if let type = initial.additionalFieldType, let predefinedTag = initial.predefinedTag {
            _destinationAdditionalFieldText.send(predefinedTag)
            destinationAdditionalDidChange(value: predefinedTag, type: type)
        }
    }

    func update(address: SendAddress?, additionalField: String?) {
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
            style: .address(networkName: initial.networkName),
            input: _destinationText.eraseToAnyPublisher(),
            isValidating: _isValidatingDestination.eraseToAnyPublisher(),
            isDisabled: .just(output: false),
            addressTextViewHeightModel: addressTextViewHeightModel,
            errorText: _destinationError.eraseToAnyPublisher()
        ) { [weak self] in
            self?.destinationDidChange(address: $0, source: .textField)
        } didPasteDestination: { [weak self] in
            self?._destinationText.send($0)
            self?.destinationDidChange(address: $0, source: .pasteButton)
        }

        additionalFieldViewModel = initial.additionalFieldType.map { additionalFieldType in
            SendDestinationTextViewModel(
                style: .additionalField(name: additionalFieldType.name),
                input: _destinationAdditionalFieldText.eraseToAnyPublisher(),
                isValidating: .just(output: false),
                isDisabled: _canChangeAdditionalField.map { !$0 }.eraseToAnyPublisher(),
                addressTextViewHeightModel: .init(),
                errorText: _destinationAdditionalFieldError.eraseToAnyPublisher()
            ) { [weak self] in
                self?.destinationAdditionalDidChange(value: $0, type: additionalFieldType)
            } didPasteDestination: { [weak self] in
                self?._destinationAdditionalFieldText.send($0)
            }
        }
    }

    private func destinationDidChange(address: String, source: Analytics.DestinationAddressSource) {
        guard !address.isEmpty else {
            _destinationError.send(nil)
            output?.destinationDidChanged(.none)
            return
        }

        runTask(in: self) { viewModel in
            await runOnMain { viewModel._isValidatingDestination.send(true) }

            do {
                let address = try await viewModel.processor.proceed(destination: address)
                viewModel.output?.destinationDidChanged(.init(value: address, source: source))

                await runOnMain {
                    viewModel._destinationValid.send(true)
                    viewModel._destinationError.send(.none)
                }

                Analytics.logDestinationAddress(isAddressValid: true, source: source)
            } catch {
                if error is CancellationError { return }

                viewModel.output?.destinationDidChanged(.none)

                await runOnMain {
                    viewModel._destinationValid.send(false)
                    viewModel._destinationError.send(error)
                }

                Analytics.logDestinationAddress(isAddressValid: false, source: source)
            }

            await runOnMain { viewModel._isValidatingDestination.send(false) }
        }
    }

    private func destinationAdditionalDidChange(value: String, type: SendAdditionalFields) {
        guard !value.isEmpty else {
            output?.destinationAdditionalParametersDidChanged(.empty(type: type))
            _destinationAdditionalFieldError.send(nil)
            return
        }

        do {
            let type = try processor.proceed(additionalField: value)
            output?.destinationAdditionalParametersDidChanged(type)
        } catch {
            _destinationAdditionalFieldError.send(error)
        }
    }

    private func bind() {
        _destinationValid
            .removeDuplicates()
            .delay(for: 0.01, scheduler: DispatchQueue.main) // HACK: making sure it doesn't interfere with textview's updates
            .sink { [weak self] destinationValid in
                self?.showSuggestedDestinations = !destinationValid
            }
            .store(in: &bag)

        transactionHistoryPublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, state -> [SendSuggestedDestinationTransactionRecord] in
                guard case .loaded(let records) = state else {
                    return []
                }

                let transactions = records
                    .compactMap { viewModel.transactionHistoryMapper.mapSuggestedRecord($0) }
                    .prefix(Constants.numberOfRecentTransactions)
                    .sorted { $0.date > $1.date }

                return Array(transactions)
            }
            .sink { [weak self] recentTransactions in
                self?.setup(recentTransactions: recentTransactions)
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
            self?.destinationDidChange(address: destination.address, source: destination.type.source)

            if let additionalField = destination.additionalField {
                self?._destinationAdditionalFieldText.send(additionalField)
            }
        }
    }
}

extension SendDestinationViewModel: AuxiliaryViewAnimatable {}

extension SendDestinationViewModel {
    struct InitialModel {
        typealias SuggestedWallet = (name: String, address: String)

        let networkName: String
        let additionalFieldType: SendAdditionalFields?
        let suggestedWallets: [SuggestedWallet]
        let transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never>

        let predefinedDestination: String?
        let predefinedTag: String?
    }
}

private extension SendSuggestedDestination.`Type` {
    var source: Analytics.DestinationAddressSource {
        switch self {
        case .otherWallet:
            return .myWallet
        case .recentAddress:
            return .recentAddress
        }
    }
}

private extension SendDestinationViewModel {
    enum Constants {
        static let numberOfRecentTransactions = 10
    }
}
