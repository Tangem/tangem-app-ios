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

enum DestinationAdditionalFieldType {
    case notSupported
    case empty(type: SendAdditionalFields)
    case filled(type: SendAdditionalFields, value: String, params: TransactionParams)
}

class SendModel {
    var destinationValid: AnyPublisher<Bool, Never> {
        _destination.map { $0 != nil }.eraseToAnyPublisher()
    }

    var amountValid: AnyPublisher<Bool, Never> {
        validatedAmount.map { $0 != nil }.eraseToAnyPublisher()
    }

    var feeValid: AnyPublisher<Bool, Never> {
        fee.map { $0 != nil }.eraseToAnyPublisher()
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

    var validatedAmountValue: Amount? {
        validatedAmount.value
    }

    var destinationPublisher: AnyPublisher<SendAddress?, Never> {
        _destination.eraseToAnyPublisher()
    }

    // MARK: - Data

    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<DestinationAdditionalFieldType, Never>
    private let validatedAmount = CurrentValueSubject<Amount?, Never>(nil)
    private let fee = CurrentValueSubject<Fee?, Never>(nil)

    private let _transactionCreationError = CurrentValueSubject<Error?, Never>(nil)
    private let _withdrawalNotification = CurrentValueSubject<WithdrawalNotification?, Never>(nil)
    private let transaction = CurrentValueSubject<BlockchainSdk.Transaction?, Never>(nil)

    // MARK: - Raw data

    private var userInputAmount = CurrentValueSubject<Amount?, Never>(nil)

    private var _selectedFeeOption = CurrentValueSubject<FeeOption, Never>(.market)
    private var _feeValues = CurrentValueSubject<[FeeOption: LoadingValue<Fee>], Never>([:])
    private var _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _isSending = CurrentValueSubject<Bool, Never>(false)
    private let _transactionTime = CurrentValueSubject<Date?, Never>(nil)
    private let _transactionURL = CurrentValueSubject<URL?, Never>(nil)

    private let _sendError = PassthroughSubject<Error?, Never>()
    private let _customFee = CurrentValueSubject<Fee?, Never>(nil)

    // MARK: - Errors (raw implementation)

    private let _amountError = CurrentValueSubject<Error?, Never>(nil)
    private let _feeError = CurrentValueSubject<Error?, Never>(nil)

    // MARK: - Private stuff

    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let sendType: SendType
    private var destinationResolutionRequest: Task<Void, Error>?
    private var didSetCustomFee = false
    private var feeUpdatePublisher: AnyPublisher<FeeUpdateResult, Error>?
    private var bag: Set<AnyCancellable> = []

    var currencySymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    // MARK: - Public interface

    init(walletModel: WalletModel, transactionSigner: TransactionSigner, sendType: SendType) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.sendType = sendType

        if let destination = sendType.predefinedDestination {
            _destination = .init(SendAddress(value: destination, source: .sellProvider))
        } else {
            _destination = .init(nil)
        }

        let fields = SendAdditionalFields.fields(for: walletModel.blockchainNetwork.blockchain)
        let type = fields.map { DestinationAdditionalFieldType.empty(type: $0) } ?? .notSupported
        _destinationAdditionalField = .init(type)

        bind()

        if let amount = sendType.predefinedAmount {
            setAmount(amount)
            updateAndValidateAmount(amount)
        }

        // Update the fees in case we have all prerequisites specified
        if let predefinedDestination = sendType.predefinedDestination {
            updateFees(amount: validatedAmountValue, destination: predefinedDestination)
                .sink()
                .store(in: &bag)
        }
    }

    func useMaxAmount() {
        let amountType = walletModel.amountType
        if let amount = walletModel.wallet.amounts[amountType] {
            setAmount(amount)
        }
    }

    func currentTransaction() -> BlockchainSdk.Transaction? {
        transaction.value
    }

    func updateFees() -> AnyPublisher<FeeUpdateResult, Error> {
        updateFees(amount: validatedAmount.value, destination: _destination.value?.value)
    }

    func setCustomFee(_ customFee: Fee?) {
        guard _customFee.value?.amount != customFee?.amount else {
            return
        }

        didSetCustomFee = true
        _customFee.send(customFee)

        if case .custom = selectedFeeOption {
            fee.send(customFee)
        }

        if _feeValues.value[.custom]?.value != customFee,
           let customFee {
            _feeValues.value[.custom] = .loaded(customFee)
        }
    }

    func send() {
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
        userInputAmount
            .removeDuplicates()
            .sink { [weak self] amount in
                self?.updateAndValidateAmount(amount)
            }
            .store(in: &bag)

        fee
            .removeDuplicates()
            .sink { [weak self] fee in
                self?.validateFee(fee)
            }
            .store(in: &bag)

        _feeValues
            .sink { [weak self] feeValues in
                guard let self else { return }

                fee.send(feeValues[selectedFeeOption]?.value)
            }
            .store(in: &bag)

        #warning("TODO: create TX after a delay")
        Publishers.CombineLatest3(validatedAmount, _destination, fee)
            .removeDuplicates {
                $0 == $1
            }
            .map { [weak self] validatedAmount, validatedDestination, fee -> Result<BlockchainSdk.Transaction, Error> in
                guard
                    let self,
                    let validatedAmount,
                    let destination = validatedDestination?.value,
                    let fee
                else {
                    self?._isFeeIncluded.send(false)
                    return .failure(ValidationError.invalidAmount)
                }

                do {
                    #warning("TODO: Use await validation")
                    let includeFee = shouldIncludeFee(fee, into: validatedAmount)
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
                    return withdrawalValidator.withdrawalNotification(amount: transaction.amount, fee: transaction.fee.amount)
                }
                .sink { [weak self] in
                    self?._withdrawalNotification.send($0)
                }
                .store(in: &bag)
        }
    }

    @discardableResult
    private func updateFees(amount: Amount?, destination: String?) -> AnyPublisher<FeeUpdateResult, Error> {
        guard let amount, let destination else {
            _feeValues.send([:])
            return .anyFail(error: WalletError.failedToGetFee)
        }

        let oldFee = fee.value

        let loadingFeeValues: [FeeOption: LoadingValue<Fee>] = Dictionary(
            feeOptions.map { ($0, LoadingValue<Fee>.loading) },
            uniquingKeysWith: { value1, _ in value1 }
        )
        _feeValues.send(loadingFeeValues)

        return walletModel
            .getFee(amount: amount, destination: destination)
            .withWeakCaptureOf(self)
            .map { (self, fees) in
                self.feeValues(fees)
            }
            .handleEvents(receiveOutput: { [weak self] feeValues in
                self?._feeValues.send(feeValues)
            }, receiveCompletion: { [weak self] completion in
                guard let self else { return }

                feeUpdatePublisher = nil

                if case .failure = completion {
                    let feeValuePairs: [(FeeOption, LoadingValue<Fee>)] = feeOptions.map { ($0, .failedToLoad(error: WalletError.failedToGetFee)) }
                    let feeValues = Dictionary(feeValuePairs, uniquingKeysWith: { v1, _ in v1 })
                    _feeValues.send(feeValues)
                }
            })
            .withWeakCaptureOf(self)
            .tryMap { (self, feeValues) in
                guard
                    let selectedFee = feeValues[self.selectedFeeOption],
                    let selectedFeeValue = selectedFee.value
                else {
                    throw WalletError.failedToGetFee
                }
                return FeeUpdateResult(oldFee: oldFee?.amount, newFee: selectedFeeValue.amount)
            }
            .eraseToAnyPublisher()
    }

    private func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool {
        guard
            fee.amount.type == amount.type,
            amount >= fee.amount
        else {
            return false
        }

        do {
            try walletModel.transactionCreator.validate(amount: amount, fee: fee)
        } catch {
            let validationError = error as? ValidationError
            if case .totalExceedsBalance = validationError {
                return true
            }
        }
        return false
    }

    private func explorerUrl(from hash: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        return provider.url(transaction: hash)
    }

    // MARK: - Amount

    func setAmount(_ amount: Amount?) {
        let newAmount: Amount? = (amount?.isZero ?? true) ? nil : amount

        guard userInputAmount.value != newAmount else { return }

        userInputAmount.send(newAmount)
    }

    /// Convenience method
    /// NOTE: this action resets the "is fee included" flag
    func setAmount(_ decimal: Decimal?) {
        let amount: Amount?
        if let decimal {
            amount = Amount(type: walletModel.amountType, currencySymbol: currencySymbol, value: decimal, decimals: walletModel.decimalCount)
        } else {
            amount = nil
        }
        setAmount(amount)
    }

    private func updateAndValidateAmount(_ newAmount: Amount?) {
        let validatedAmount: Amount?
        let amountError: Error?

        if let newAmount {
            do {
                try walletModel.transactionValidator.validate(amount: newAmount)

                validatedAmount = newAmount
                amountError = nil
            } catch let validationError {
                validatedAmount = nil
                amountError = validationError
            }
        } else {
            validatedAmount = nil
            amountError = nil
        }

        self.validatedAmount.send(validatedAmount)
        _amountError.send(amountError)
    }

    private func validateFee(_ fee: Fee?) {
        let feeError: Error?

        if let fee {
            do {
                try walletModel.transactionValidator.validate(fee: fee.amount)
                feeError = nil
            } catch let validationError {
                feeError = validationError
            }
        } else {
            feeError = nil
        }

        _feeError.send(feeError)
    }

    // MARK: - Fees

    func didSelectFeeOption(_ feeOption: FeeOption) {
        _selectedFeeOption.send(feeOption)

        if let newFee = _feeValues.value[feeOption]?.value {
            fee.send(newFee)
        }
    }

    private func feeValues(_ fees: [Fee]) -> [FeeOption: LoadingValue<Fee>] {
        switch fees.count {
        case 1:
            return [
                .market: .loaded(fees[0]),
            ]
        case 3:
            var fees: [FeeOption: LoadingValue<Fee>] = [
                .slow: .loaded(fees[0]),
                .market: .loaded(fees[1]),
                .fast: .loaded(fees[2]),
            ]

            if feeOptions.contains(.custom) {
                if let customFee = _customFee.value,
                   didSetCustomFee {
                    fees[.custom] = .loaded(customFee)
                } else {
                    fees[.custom] = fees[.market]
                }
            }

            return fees
        default:
            return [:]
        }
    }
}

// MARK: - SendAmountViewModelInput

extension SendModel: SendAmountViewModelInput {
    var amountError: AnyPublisher<Error?, Never> { _amountError.eraseToAnyPublisher() }
}

extension SendModel: SendDestinationInput, SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendFeeViewModelInput

extension SendModel: SendFeeViewModelInput {
    var amountPublisher: AnyPublisher<Amount?, Never> {
        validatedAmount.eraseToAnyPublisher()
    }

    var selectedFeeOption: FeeOption {
        _selectedFeeOption.value
    }

    #warning("TODO")
    var feeOptions: [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            var options: [FeeOption] = [.slow, .market, .fast]
            if walletModel.supportsCustomFees {
                options.append(.custom)
            }
            return options
        } else {
            return [.market]
        }
    }

    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> {
        _feeValues.eraseToAnyPublisher()
    }

    var tokenItem: TokenItem {
        walletModel.tokenItem
    }

    var customFeePublisher: AnyPublisher<Fee?, Never> {
        _customFee.eraseToAnyPublisher()
    }

    var canIncludeFeeIntoAmount: Bool {
        sendType.canIncludeFeeIntoAmount && walletModel.amountType == walletModel.feeTokenItem.amountType
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }
}

// MARK: - SendSummaryViewModelInput

extension SendModel: SendSummaryViewModelInput {
    var destinationTextPublisher: AnyPublisher<String, Never> {
        _destination
            .receive(on: DispatchQueue.main) // Move this to UI layer
            .compactMap { $0?.value }
            .eraseToAnyPublisher()
    }

    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> {
        _destinationAdditionalField
            .withWeakCaptureOf(self)
            .map { viewModel, field in
                switch field {
                case .filled(let type, let value, _):
                    return (type, value)
                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    var transactionAmountPublisher: AnyPublisher<Amount?, Never> {
        transaction
            .map(\.?.amount)
            .eraseToAnyPublisher()
    }

    var feeValuePublisher: AnyPublisher<BlockchainSdk.Fee?, Never> {
        fee.eraseToAnyPublisher()
    }

    var selectedFeeOptionPublisher: AnyPublisher<FeeOption, Never> {
        _selectedFeeOption.eraseToAnyPublisher()
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
    var userInputAmountValue: Amount? {
        userInputAmount.value
    }

    var destinationText: String? {
        _destination.value?.value
    }

    var additionalField: (SendAdditionalFields, String)? {
        switch _destinationAdditionalField.value {
        case .notSupported, .empty:
            return nil
        case .filled(let type, let value, _):
            return (type, value)
        }
    }

    var feeValue: Fee? {
        fee.value
    }

    var feeText: String {
        fee.value?.amount.string() ?? ""
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
    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transactionCreationError.eraseToAnyPublisher()
    }

    var withdrawalNotification: AnyPublisher<WithdrawalNotification?, Never> {
        _withdrawalNotification.eraseToAnyPublisher()
    }
}

// MARK: - SendFiatCryptoAdapterOutput

extension SendModel: SendFiatCryptoAdapterOutput {}

// MARK: - CustomFeeServiceInput, CustomFeeServiceOutput

extension SendModel: CustomFeeServiceInput, CustomFeeServiceOutput {
    var customFee: Fee? {
        _customFee.value
    }
}
