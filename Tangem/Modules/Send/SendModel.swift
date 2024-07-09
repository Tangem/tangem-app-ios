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
import TangemSdk

protocol SendModelUIDelegate: AnyObject {
    func showAlert(_ alert: AlertBinder)
}

class SendModel {
    typealias BSDKTransaction = BlockchainSdk.Transaction

    // MARK: - Delegate

    weak var delegate: SendModelUIDelegate?

    // MARK: - Data

    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<SendDestinationAdditionalField, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>
    private let _selectedFee = CurrentValueSubject<SendFee?, Never>(nil)
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transaction = CurrentValueSubject<BSDKTransaction?, Never>(nil)
    private let _transactionError = CurrentValueSubject<Error?, Never>(nil)
    private let _transactionTime = PassthroughSubject<Date?, Never>()

    private let _withdrawalNotification = CurrentValueSubject<WithdrawalNotification?, Never>(nil)

    // MARK: - Dependensies

    var sendAmountInteractor: SendAmountInteractor!
    var sendFeeInteractor: SendFeeInteractor!
    var informationRelevanceService: InformationRelevanceService!

    // MARK: - Private stuff

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let sendTransactionDispatcher: SendTransactionDispatcher
    private let transactionSigner: TransactionSigner
    private let transactionCreator: TransactionCreator
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let emailDataProvider: EmailDataProvider
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        sendTransactionDispatcher: SendTransactionDispatcher,
        transactionCreator: TransactionCreator,
        transactionSigner: TransactionSigner,
        feeIncludedCalculator: FeeIncludedCalculator,
        emailDataProvider: EmailDataProvider,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        predefinedValues: PredefinedValues,
        coordinator: SendRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.sendTransactionDispatcher = sendTransactionDispatcher
        self.transactionSigner = transactionSigner
        self.transactionCreator = transactionCreator
        self.feeIncludedCalculator = feeIncludedCalculator
        self.emailDataProvider = emailDataProvider
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.coordinator = coordinator

        _destination = .init(predefinedValues.destination)
        _destinationAdditionalField = .init(predefinedValues.tag)
        _amount = .init(predefinedValues.amount)

        bind()
    }

    private func openMail(transaction: BSDKTransaction, error: SendTxError) {
        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: _isFeeIncluded.value,
            lastError: error
        )
        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }
}

// MARK: - Validation

private extension SendModel {
    private func bind() {
        Publishers
            .CombineLatest3(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value },
                _selectedFee.compactMap { $0?.value.value }
            )
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .tryAsyncMap { manager, args async throws -> BSDKTransaction in
                try await manager.makeTransaction(amountValue: args.0, destination: args.1, fee: args.2)
            }
            .mapToResult()
            .sink { [weak self] result in
                switch result {
                case .failure(let error):
                    self?._transactionError.send(error)
                case .success(let transaction):
                    self?._transaction.send(transaction)
                }
            }
            .store(in: &bag)

        guard let withdrawalValidator = walletModel.withdrawalNotificationProvider else {
            return
        }

        _transaction
            .map { transaction in
                transaction.flatMap {
                    withdrawalValidator.withdrawalNotification(amount: $0.amount, fee: $0.fee)
                }
            }
            .sink { [weak self] in
                self?._withdrawalNotification.send($0)
            }
            .store(in: &bag)
    }

    private func makeTransaction(amountValue: Decimal, destination: String, fee: Fee) async throws -> BSDKTransaction {
        var amount = makeAmount(decimal: amountValue)
        let includeFee = feeIncludedCalculator.shouldIncludeFee(fee, into: amount)
        _isFeeIncluded.send(includeFee)

        if includeFee {
            amount = makeAmount(decimal: amount.value - fee.amount.value)
        }

        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: destination
        )

        return transaction
    }

    private func makeAmount(decimal: Decimal) -> Amount {
        Amount(with: walletModel.tokenItem.blockchain, type: walletModel.tokenItem.amountType, value: decimal)
    }
}

// MARK: - Send

private extension SendModel {
    private func sendIfInformationIsActual() -> AnyPublisher<SendTransactionSentResult, Never> {
        if informationRelevanceService.isActual {
            return send()
        }

        return informationRelevanceService
            .updateInformation()
            .mapToResult()
            .withWeakCaptureOf(self)
            .flatMap { manager, result -> AnyPublisher<SendTransactionSentResult, Never> in
                switch result {
                case .failure:
                    return Deferred {
                        Future { promise in
                            manager.delegate?.showAlert(SendAlertBuilder.makeFeeRetryAlert {
                                promise(.success(()))
                            })
                        }
                    }
                    .withWeakCaptureOf(self)
                    .flatMap { manager, _ in
                        manager.send()
                    }
                    .eraseToAnyPublisher()

                case .success(.feeWasIncreased):
                    manager.delegate?.showAlert(
                        AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
                    )

                    return Empty().eraseToAnyPublisher()
                case .success(.ok):
                    return manager.send()
                }
            }
            .eraseToAnyPublisher()
    }

    private func send() -> AnyPublisher<SendTransactionSentResult, Never> {
        guard let transaction = _transaction.value else {
            return Empty().eraseToAnyPublisher()
        }

        return sendTransactionSender
            .send(transaction: transaction)
            .mapToResult()
            .withWeakCaptureOf(self)
            .compactMap { sender, result in
                return sender.proceed(transaction: transaction, result: result)
            }
            .eraseToAnyPublisher()
    }

    private func proceed(transaction: BSDKTransaction, result: Result<SendTransactionSentResult, SendTxError>) -> SendTransactionSentResult? {
        switch result {
        case .success(let result):
            proceed(transaction: transaction, result: result)
            return result
        case .failure(let error):
            proceed(transaction: transaction, error: error)
            return nil
        }
    }

    private func proceed(transaction: BSDKTransaction, result: SendTransactionSentResult) {
        if walletModel.isDemo {
            let alert = AlertBuilder.makeAlert(
                title: "",
                message: Localization.alertDemoFeatureDisabled,
                primaryButton: .default(.init(Localization.commonOk)) { [weak self] in
                    self?.coordinator?.dismiss()
                }
            )

            delegate?.showAlert(alert)
        } else {
            logTransactionAnalytics()
        }

        if let token = transaction.amount.type.token {
            UserWalletFinder().addToken(
                token,
                in: walletModel.blockchainNetwork.blockchain,
                for: transaction.destinationAddress
            )
        }
    }

    private func proceed(transaction: BSDKTransaction, error: SendTxError) {
        Analytics.log(event: .sendErrorTransactionRejected, params: [
            .token: walletModel.tokenItem.currencySymbol,
        ])

        switch error.error {
        case TangemSdkError.userCancelled:
            return
        case WalletError.noAccount(_, let amount):
            let amountFormatted = Amount(
                with: walletModel.blockchainNetwork.blockchain,
                type: walletModel.amountType,
                value: amount
            ).string()

            // "Use TransactionValidator async validate to get this warning before send tx"
            let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
            let message = Localization.sendNotificationInvalidReserveAmountText
            delegate?.showAlert(AlertBinder(title: title, message: message))
        default:
            let errorCode: String
            let reason = String(error.localizedDescription.dropTrailingPeriod)
            if let errorCodeProviding = error as? ErrorCodeProviding {
                errorCode = "\(errorCodeProviding.errorCode)"
            } else {
                errorCode = "-"
            }

            let sendError = SendError(
                title: Localization.sendAlertTransactionFailedTitle,
                message: Localization.sendAlertTransactionFailedText(reason, errorCode),
                error: error,
                openMailAction: { [weak self] error in
                    self?.openMail(transaction: transaction, error: error)
                }
            )

            delegate?.showAlert(sendError.alertBinder)
        }
    }
}

// MARK: - SendDestinationInput

extension SendModel: SendDestinationInput {
    var destinationPublisher: AnyPublisher<SendAddress, Never> {
        _destination
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> {
        _destinationAdditionalField.eraseToAnyPublisher()
    }
}

// MARK: - SendDestinationOutput

extension SendModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendAmountInput

extension SendModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    var amountPublisher: AnyPublisher<SendAmount?, Never> {
        _amount.eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension SendModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
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

// MARK: - SendSummaryInput, SendSummaryOutput

extension SendModel: SendSummaryInput, SendSummaryOutput {
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> {
        _transaction.eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension SendModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SendModel: SendBaseInput, SendBaseOutput {
    var isLoading: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    func sendTransaction() -> AnyPublisher<SendTransactionSentResult, Never> {
        sendIfInformationIsActual()
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    // TODO: Refactoring in https://tangem.atlassian.net/browse/IOS-7196
    var selectedSendFeePublisher: AnyPublisher<SendFee?, Never> {
        selectedFeePublisher
    }

    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeInteractor.feesPublisher
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<(any Error)?, Never> {
        .just(output: nil) // TODO: Check it
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transactionError.eraseToAnyPublisher()
    }

    var withdrawalNotification: AnyPublisher<WithdrawalNotification?, Never> {
        _withdrawalNotification.eraseToAnyPublisher()
    }
}

// MARK: - Analytics

private extension SendModel {
    func logTransactionAnalytics() {
        let sourceValue: Analytics.ParameterValue
//        switch sendType {
//        case .send:
        sourceValue = .transactionSourceSend
//        case .sell:
//            sourceValue = .transactionSourceSell
//        }

        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee?.option)

        Analytics.log(event: .transactionSent, params: [
            .source: sourceValue.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.blockchainNetwork.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter().rawValue,
        ])

        if let amount {
            Analytics.log(.sendSelectedCurrency, params: [
                .commonType: amount.type.analyticParameter,
            ])
        }
    }

    func additionalFieldAnalyticsParameter() -> Analytics.ParameterValue {
        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
        switch _destinationAdditionalField.value {
        case .notSupported: .null
        case .empty: .empty
        case .filled: .full
        }
    }
}

extension SendAmount.SendAmountType {
    var analyticParameter: Analytics.ParameterValue {
        switch self {
        case .typical: .token
        case .alternative: .selectedCurrencyApp
        }
    }
}

// MARK: - Models

extension SendModel {
    struct PredefinedValues {
        let destination: SendAddress?
        let tag: SendDestinationAdditionalField
        let amount: SendAmount?
    }
}
