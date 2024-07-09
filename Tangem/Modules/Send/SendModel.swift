//
//  SendModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BigInt
import BlockchainSdk

protocol SendModelUIDelegate: AnyObject {
    func showAlert(_ alert: AlertBinder)
}

class SendModel {
    var destinationValid: AnyPublisher<Bool, Never> {
        _destination.map { $0 != nil }.eraseToAnyPublisher()
    }

    var amountValid: AnyPublisher<Bool, Never> {
        _amount.map { $0 != nil }.eraseToAnyPublisher()
    }

    var feeValid: AnyPublisher<Bool, Never> {
        _selectedFee.map { $0 != nil }.eraseToAnyPublisher()
    }

    var sendError: AnyPublisher<Error?, Never> {
        _sendError.eraseToAnyPublisher()
    }

    var isFeeIncluded: Bool {
        _isFeeIncluded.value
    }

    var transactionFinished: AnyPublisher<Bool, Never> {
        _transactionTime
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Delegate

    weak var delegate: SendModelUIDelegate?

    // MARK: - Data

    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<DestinationAdditionalFieldType, Never>
    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedFee = CurrentValueSubject<SendFee?, Never>(nil)
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transactionCreationError = CurrentValueSubject<Error?, Never>(nil)
    private let _withdrawalNotification = CurrentValueSubject<WithdrawalNotification?, Never>(nil)
    private let transaction = CurrentValueSubject<BlockchainSdk.Transaction?, Never>(nil)

    // MARK: - Raw data

    private let _isSending = CurrentValueSubject<Bool, Never>(false)
    private let _transactionTime = CurrentValueSubject<Date?, Never>(nil)
    private let _transactionURL = CurrentValueSubject<URL?, Never>(nil)

    private let _sendError = PassthroughSubject<Error?, Never>()

    // MARK: - Private stuff

    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let sendFeeInteractor: SendFeeInteractor
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let informationRelevanceService: InformationRelevanceService
    private let sendType: SendType

    private var bag: Set<AnyCancellable> = []

    var currencySymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    // MARK: - Public interface

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner,
        sendFeeInteractor: SendFeeInteractor,
        feeIncludedCalculator: FeeIncludedCalculator,
        informationRelevanceService: InformationRelevanceService,
        sendType: SendType
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.sendFeeInteractor = sendFeeInteractor
        self.feeIncludedCalculator = feeIncludedCalculator
        self.informationRelevanceService = informationRelevanceService
        self.sendType = sendType

        let destination = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
        _destination = .init(destination)

        let fields = SendAdditionalFields.fields(for: walletModel.blockchainNetwork.blockchain)
        let type = fields.map { DestinationAdditionalFieldType.empty(type: $0) } ?? .notSupported
        _destinationAdditionalField = .init(type)

        bind()

        // Update the fees in case we have all prerequisites specified
        if sendType.predefinedAmount != nil, sendType.predefinedDestination != nil {
            updateFees()
        }
    }

    func currentTransaction() -> BlockchainSdk.Transaction? {
        transaction.value
    }

    func updateFees() {
        sendFeeInteractor.updateFees()
    }

    func send() {
        if informationRelevanceService.isActual {
            sendTransaction()
            return
        }

        informationRelevanceService
            .updateInformation()
            .sink { [weak self] completion in
                guard case .failure = completion else {
                    return
                }

                self?.delegate?.showAlert(
                    SendAlertBuilder.makeFeeRetryAlert { self?.send() }
                )

            } receiveValue: { [weak self] result in
                switch result {
                case .feeWasIncreased:
                    self?.delegate?.showAlert(
                        AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
                    )
                case .ok:
                    self?.sendTransaction()
                }
            }
            .store(in: &bag)
    }

    func sendTransaction() {
        guard var transaction = transaction.value else {
            AppLog.shared.debug("Transaction object hasn't been created")
            return
        }

        #warning("TODO: loading view")
        #warning("TODO: demo")

        if case .filled(_, _, let params) = _destinationAdditionalField.value {
            transaction.params = params
        }

        _isSending.send(true)
        walletModel.send(transaction, signer: transactionSigner)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }

                _isSending.send(false)

                if case .failure(let error) = completion,
                   !error.toTangemSdkError().isUserCancelled {
                    _sendError.send(error)
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }

                if let transactionURL = explorerUrl(from: result.hash) {
                    _transactionURL.send(transactionURL)
                }
                _transactionTime.send(Date())
            }
            .store(in: &bag)
    }

    private func bind() {
        #warning("TODO: create TX after a delay")
        Publishers.CombineLatest3(cryptoAmountPublisher, _destination, _selectedFee)
            .removeDuplicates {
                $0 == $1
            }
            .map { [weak self] validatedAmount, validatedDestination, fee -> Result<BlockchainSdk.Transaction, Error> in
                guard
                    let self,
                    let destination = validatedDestination?.value,
                    let fee = fee?.value.value
                else {
                    self?._isFeeIncluded.send(false)
                    return .failure(ValidationError.invalidAmount)
                }

                do {
                    #warning("TODO: Use await validation")
                    let includeFee = feeIncludedCalculator.shouldIncludeFee(fee, into: validatedAmount)
                    let transactionAmount = includeFee ? validatedAmount - fee.amount : validatedAmount
                    _isFeeIncluded.send(includeFee)

                    try walletModel.transactionValidator.validateTotal(amount: transactionAmount, fee: fee.amount)

                    let transaction = try walletModel.transactionCreator.createTransaction(
                        amount: transactionAmount,
                        fee: fee,
                        destinationAddress: destination
                    )
                    return .success(transaction)
                } catch {
                    AppLog.shared.debug("Failed to create transaction")
                    return .failure(error)
                }
            }
            .sink { [weak self] result in
                switch result {
                case .success(let transaction):
                    self?.transaction.send(transaction)
                    self?._transactionCreationError.send(nil)
                case .failure(let error):
                    self?.transaction.send(nil)
                    self?._transactionCreationError.send(error)
                }
            }
            .store(in: &bag)

        if let withdrawalValidator = walletModel.withdrawalNotificationProvider {
            transaction
                .map { transaction in
                    guard let transaction else { return nil }
                    return withdrawalValidator.withdrawalNotification(amount: transaction.amount, fee: transaction.fee)
                }
                .sink { [weak self] in
                    self?._withdrawalNotification.send($0)
                }
                .store(in: &bag)
        }
    }

    private func explorerUrl(from hash: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        return provider.url(transaction: hash)
    }

    private func makeAmount(decimal: Decimal) -> Amount? {
        Amount(with: walletModel.tokenItem.blockchain, type: walletModel.tokenItem.amountType, value: decimal)
    }
}

// MARK: - SendAmountInput, SendAmountOutput

extension SendModel: SendAmountInput, SendAmountOutput {
    var amount: SendAmount? { _amount.value }

    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendDestinationInput

extension SendModel: SendDestinationInput {
    var destinationPublisher: AnyPublisher<SendAddress, Never> {
        _destination
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var additionalFieldPublisher: AnyPublisher<DestinationAdditionalFieldType, Never> {
        _destinationAdditionalField.eraseToAnyPublisher()
    }
}

// MARK: - SendDestinationOutput

extension SendModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendFeeInput

extension SendModel: SendFeeInput {
    var selectedFee: SendFee? {
        _selectedFee.value
    }

    var selectedFeePublisher: AnyPublisher<SendFee?, Never> {
        _selectedFee.eraseToAnyPublisher()
    }

    var cryptoAmountPublisher: AnyPublisher<BlockchainSdk.Amount, Never> {
        _amount
            .withWeakCaptureOf(self)
            .compactMap { model, amount in
                amount?.crypto.flatMap { model.makeAmount(decimal: $0) }
            }
            .eraseToAnyPublisher()
    }

    var destinationAddressPublisher: AnyPublisher<String?, Never> {
        _destination.map { $0?.value }.eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension SendModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        _selectedFee.send(fee)
    }
}

// MARK: - SendSummaryViewModelInput

extension SendModel: SendSummaryViewModelInput {
    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }

    var destinationTextPublisher: AnyPublisher<String, Never> {
        _destination
            .receive(on: DispatchQueue.main) // Move this to UI layer
            .compactMap { $0?.value }
            .eraseToAnyPublisher()
    }

    var transactionAmountPublisher: AnyPublisher<Amount?, Never> {
        transaction
            .map(\.?.amount)
            .eraseToAnyPublisher()
    }

    var canEditAmount: Bool {
        sendType.predefinedAmount == nil
    }

    var canEditDestination: Bool {
        sendType.predefinedDestination == nil
    }

    var isSending: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishViewModelInput

extension SendModel: SendFinishViewModelInput {
    var feeValue: SendFee? {
        _selectedFee.value
    }

    var userInputAmountValue: Decimal? {
        _amount.value?.crypto
    }

    var destinationText: String? {
        _destination.value?.value
    }

    var additionalField: DestinationAdditionalFieldType {
        _destinationAdditionalField.value
    }

    var feeText: String {
        _selectedFee.value?.value.value?.amount.string() ?? ""
    }

    var transactionTime: Date? {
        _transactionTime.value
    }

    var transactionURL: URL? {
        _transactionURL.value
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeInteractor.feesPublisher()
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<(any Error)?, Never> {
        .just(output: nil) // TODO: Check it
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transactionCreationError.eraseToAnyPublisher()
    }

    var withdrawalNotification: AnyPublisher<WithdrawalNotification?, Never> {
        _withdrawalNotification.eraseToAnyPublisher()
    }
}
