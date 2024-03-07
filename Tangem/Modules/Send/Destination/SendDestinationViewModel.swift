//
//  SendDestinationViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendDestinationViewModelInput {
    var destinationValid: AnyPublisher<Bool, Never> { get }

    var isValidatingDestination: AnyPublisher<Bool, Never> { get }

    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var destinationAdditionalFieldTextPublisher: AnyPublisher<String, Never> { get }

    var destinationError: AnyPublisher<Error?, Never> { get }
    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> { get }

    var networkName: String { get }
    var blockchainNetwork: BlockchainNetwork { get }
    var walletPublicKey: Wallet.PublicKey { get }

    var additionalFieldType: SendAdditionalFields? { get }
    var additionalFieldEmbeddedInAddress: AnyPublisher<Bool, Never> { get }

    var currencySymbol: String { get }
    var walletAddresses: [String] { get }

    var transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never> { get }

    func setDestination(_ address: SendAddress)
    func setDestinationAdditionalField(_ additionalField: String)
}

class SendDestinationViewModel: ObservableObject {
    var addressViewModel: SendDestinationTextViewModel?
    var additionalFieldViewModel: SendDestinationTextViewModel?
    var suggestedDestinationViewModel: SendSuggestedDestinationViewModel?

    @Published var destinationErrorText: String?
    @Published var destinationAdditionalFieldErrorText: String?
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false
    @Published var showSuggestedDestinations = true

    var didProperlyDisappear: Bool = false

    private let input: SendDestinationViewModelInput
    private let transactionHistoryMapper: TransactionHistoryMapper
    private let suggestedWallets: [SendSuggestedDestinationWallet]

    private var bag: Set<AnyCancellable> = []

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    // MARK: - Methods

    init(input: SendDestinationViewModelInput) {
        self.input = input

        transactionHistoryMapper = TransactionHistoryMapper(
            currencySymbol: input.currencySymbol,
            walletAddresses: input.walletAddresses,
            showSign: false
        )

        suggestedWallets = Self.userWalletRepository
            .models
            .compactMap { userWalletModel in
                let walletModels = userWalletModel.walletModelsManager.walletModels
                let walletModel = walletModels.first { walletModel in
                    walletModel.blockchainNetwork == input.blockchainNetwork &&
                        walletModel.wallet.publicKey != input.walletPublicKey
                }
                guard let walletModel else { return nil }

                return SendSuggestedDestinationWallet(
                    name: userWalletModel.name,
                    address: walletModel.defaultAddress
                )
            }

        addressViewModel = SendDestinationTextViewModel(
            style: .address(networkName: input.networkName),
            input: input.destinationTextPublisher,
            isValidating: input.isValidatingDestination,
            isDisabled: .just(output: false),
            errorText: input.destinationError
        ) { [weak self] in
            self?.input.setDestination(SendAddress(value: $0, inputSource: .textField))
        } didPasteDestination: { [weak self] in
            self?.input.setDestination(SendAddress(value: $0, inputSource: .pasteButton))
        }

        if let additionalFieldType = input.additionalFieldType,
           let name = additionalFieldType.name {
            additionalFieldViewModel = SendDestinationTextViewModel(
                style: .additionalField(name: name),
                input: input.destinationAdditionalFieldTextPublisher,
                isValidating: .just(output: false),
                isDisabled: input.additionalFieldEmbeddedInAddress,
                errorText: input.destinationAdditionalFieldError
            ) { [weak self] in
                self?.input.setDestinationAdditionalField($0)
            } didPasteDestination: { [weak self] in
                self?.input.setDestinationAdditionalField($0)
            }
        }

        bind()
    }

    private func bind() {
        input
            .destinationError
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.destinationErrorText, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .destinationAdditionalFieldError
            .map {
                $0?.localizedDescription
            }
            .assign(to: \.destinationAdditionalFieldErrorText, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .destinationValid
            .removeDuplicates()
            .sink { [weak self] destinationValid in
                withAnimation(SendView.Constants.defaultAnimation) {
                    self?.showSuggestedDestinations = !destinationValid
                }
            }
            .store(in: &bag)

        input
            .transactionHistoryPublisher
            .compactMap { [weak self] state -> [SendSuggestedDestinationTransactionRecord] in
                guard
                    let self,
                    case .loaded(let records) = state
                else {
                    return []
                }

                return records.compactMap { record in
                    self.transactionHistoryMapper.mapSuggestedRecord(record)
                }
            }
            .sink { [weak self] recentTransactions in
                guard let self else { return }

                if suggestedWallets.isEmpty, recentTransactions.isEmpty {
                    suggestedDestinationViewModel = nil
                    return
                }

                suggestedDestinationViewModel = SendSuggestedDestinationViewModel(
                    wallets: suggestedWallets,
                    recentTransactions: recentTransactions
                ) { [weak self] destination in
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)

                    self?.input.setDestination(SendAddress(value: destination.address, inputSource: destination.type.inputSource))
                    if let additionalField = destination.additionalField {
                        self?.input.setDestinationAdditionalField(additionalField)
                    }
                }
            }
            .store(in: &bag)
    }
}

extension SendDestinationViewModel: AuxiliaryViewAnimatable {}

private extension SendSuggestedDestination.`Type` {
    var inputSource: SendAddress.InputSource {
        switch self {
        case .otherWallet:
            return .otherWallet
        case .recentAddress:
            return .recentAddress
        }
    }
}
