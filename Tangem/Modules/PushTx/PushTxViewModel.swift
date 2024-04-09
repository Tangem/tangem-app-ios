//
//  PushTxViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 14/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk

class PushTxViewModel: ObservableObject {
    var destination: String { transaction.destination }

    var previousTotal: String {
        isFiatCalculation ?
            getFiat(for: previousTotalAmount, roundingType: .defaultFiat(roundingMode: .down))?.description ?? "" :
            previousTotalAmount.value.description
    }

    var currency: String {
        isFiatCalculation ? AppSettings.shared.selectedCurrencyCode : transaction.amount.currencySymbol
    }

    var walletTotalBalanceDecimals: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        return isFiatCalculation ? getFiat(for: amount, roundingType: .defaultFiat(roundingMode: .down))?.description ?? ""
            : amount?.value.description ?? ""
    }

    var walletTotalBalanceFormatted: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        let value = getDescription(for: amount, isFiat: isFiatCalculation)
        return value
    }

    var walletModel: WalletModel {
        let id = WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: amountToSend.type).id
        return userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == id })!
    }

    var previousFeeAmount: Amount { transaction.fee.amount }

    var previousTotalAmount: Amount {
        previousFeeAmount + transaction.amount
    }

    var newFee: String {
        newTransaction?.fee.description ?? "Not loaded"
    }

    @Published var amountHint: TextHint?
    @Published var sendError: AlertBinder?

    @Published var isFeeLoading: Bool = false
    @Published var isSendEnabled: Bool = false

    @Published var canFiatCalculation: Bool = true
    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = false

    @Published var amountToSend: Amount
    @Published var selectedFeeLevel: Int = 1
    @Published var fees: [Fee] = []
    @Published var selectedFee: Fee? = nil

    @Published var additionalFee: String = ""
    @Published var sendTotal: String = ""
    @Published var sendTotalSubtitle: String = ""

    @Published var shouldAmountBlink: Bool = false

    let userWalletModel: CommonUserWalletModel
    let blockchainNetwork: BlockchainNetwork
    var transaction: PendingTransactionRecord

    lazy var amountDecimal: String = "\(getFiat(for: amountToSend, roundingType: .defaultFiat(roundingMode: .down)) ?? 0)"
    lazy var amount: String = transaction.amount.description
    lazy var previousFee: String = transaction.fee.description

    private var emptyValue: String {
        getDescription(for: Amount.zeroCoin(for: blockchainNetwork.blockchain), isFiat: isFiatCalculation)
    }

    private var bag: Set<AnyCancellable> = []
    @Published private var newTransaction: BlockchainSdk.Transaction?

    private weak var coordinator: PushTxRoutable?

    init(
        transaction: PendingTransactionRecord,
        blockchainNetwork: BlockchainNetwork,
        userWalletModel: UserWalletModel,
        coordinator: PushTxRoutable
    ) {
        self.coordinator = coordinator
        self.blockchainNetwork = blockchainNetwork
        self.userWalletModel = userWalletModel as! CommonUserWalletModel
        self.transaction = transaction
        amountToSend = transaction.amount
        additionalFee = emptyValue
        sendTotal = emptyValue
        sendTotalSubtitle = emptyValue

        bind()
        fillPreviousTxInfo(isFiat: isFiatCalculation)
        loadNewFees()
    }

    func onSend() {
        send {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                let alert = AlertBuilder.makeSuccessAlert(message: Localization.sendTransactionSuccess) { [weak self] in
                    self?.dismiss()
                }

                self?.sendError = alert
            }
        }
    }

    func send(_ callback: @escaping () -> Void) {
        guard
            let tx = newTransaction,
            let pusher = walletModel.transactionPusher
        else {
            return
        }

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()
        pusher.pushTransaction(with: transaction.hash, newTransaction: tx, signer: userWalletModel.signer)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }

                appDelegate.removeLoadingView()
                if case .failure(let error) = completion {
                    if error.toTangemSdkError().isUserCancelled {
                        return
                    }

                    AppLog.shared.error(error: error, params: [
                        .blockchain: walletModel.wallet.blockchain.displayName,
                        .action: Analytics.ParameterValue.pushTx.rawValue,
                    ])

                    sendError = SendError(
                        title: Localization.feedbackSubjectTxFailed,
                        message: Localization.alertFailedToSendTransactionMessage(String(error.localizedDescription.dropTrailingPeriod)),
                        error: error,
                        openMailAction: openMail
                    )
                    .alertBinder
                } else {
                    walletModel.startUpdatingTimer()
                    callback()
                }

            }, receiveValue: { _ in })
            .store(in: &bag)
    }

    private func getDescription(for amount: Amount?, isFiat: Bool) -> String {
        isFiat ?
            getFiatFormatted(for: amount, roundingType: .defaultFiat(roundingMode: .down)) ?? "" :
            amount?.description ?? emptyValue
    }

    private func bind() {
        AppLog.shared.debug("\n\nCreating push tx view model subscriptions \n\n")

        bag.removeAll()

        $isFiatCalculation
            .withWeakCaptureOf(self)
            .sink { viewModel, isFiat in
                viewModel.fillPreviousTxInfo(isFiat: isFiat)
                viewModel.fillTotalBlock(tx: viewModel.newTransaction, isFiat: isFiat)
                viewModel.updateFeeLabel(fee: viewModel.selectedFee?.amount, isFiat: isFiat)
            }
            .store(in: &bag)

        $selectedFeeLevel
            .withWeakCaptureOf(self)
            .map { viewModel, feeLevel in
                guard viewModel.fees.count > feeLevel else {
                    return nil
                }

                let fee = viewModel.fees[feeLevel]
                return fee
            }
            .assign(to: \.selectedFee, on: self, ownership: .weak)
            .store(in: &bag)

        $fees
            .dropFirst()
            .withWeakCaptureOf(self)
            .map { viewModel, values in
                guard values.count > viewModel.selectedFeeLevel else { return nil }

                return values[viewModel.selectedFeeLevel]
            }
            .assign(to: \.selectedFee, on: self, ownership: .weak)
            .store(in: &bag)

        $isFeeIncluded
            .dropFirst()
            .withWeakCaptureOf(self)
            .map { viewModel, isFeeIncluded in
                viewModel.updateAmount(isFeeIncluded: isFeeIncluded, selectedFee: viewModel.selectedFee?.amount)
                viewModel.shouldAmountBlink = true
            }
            .sink(receiveValue: { _ in })
            .store(in: &bag)

        $selectedFee
            .dropFirst()
            .combineLatest($isFeeIncluded)
            .withWeakCaptureOf(self)
            .map { values -> (BlockchainSdk.Transaction?, Fee?) in
                let (viewModel, (fee, isFeeIncluded)) = values
                var errorMessage: String?
                defer {
                    self.amountHint = errorMessage == nil ? nil : .init(isError: true, message: errorMessage!)
                }

                guard let fee = fee else {
                    errorMessage = BlockchainSdkError.failedToLoadFee.localizedDescription
                    return (nil, fee)
                }

                guard fee.amount > viewModel.transaction.fee.amount else {
                    errorMessage = BlockchainSdkError.feeForPushTxNotEnough.localizedDescription
                    return (nil, fee)
                }

                let newAmount = if isFeeIncluded {
                    viewModel.transaction.amount + viewModel.previousFeeAmount - fee.amount
                } else {
                    viewModel.transaction.amount
                }

                var tx: BlockchainSdk.Transaction?

                do {
                    tx = try viewModel.walletModel.transactionCreator.createTransaction(
                        amount: newAmount,
                        fee: fee,
                        destinationAddress: viewModel.destination
                    )
                } catch {
                    errorMessage = error.localizedDescription
                }

                viewModel.updateAmount(isFeeIncluded: isFeeIncluded, selectedFee: fee.amount)
                return (tx, fee)
            }
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, txFee in
                let tx = txFee.0
                let fee = txFee.1
                viewModel.newTransaction = tx
                viewModel.isSendEnabled = tx != nil
                viewModel.fillTotalBlock(tx: tx, isFiat: viewModel.isFiatCalculation)
                viewModel.updateFeeLabel(fee: fee?.amount)

            })
            .store(in: &bag)
    }

    private func loadNewFees() {
        guard let pusher = walletModel.transactionPusher else {
            return
        }

        isFeeLoading = true
        pusher.getPushFee(for: transaction.hash)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isFeeLoading = false
                if case .failure(let error) = completion {
                    AppLog.shared.debug("Failed to load fee error: \(error.localizedDescription)")
                    self?.amountHint = .init(isError: true, message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] fees in
                self?.fees = fees
            })
            .store(in: &bag)
    }

    private func fillPreviousTxInfo(isFiat: Bool) {
        amount = getDescription(for: amountToSend, isFiat: isFiat)
        amountDecimal = isFiat ? getFiat(for: amountToSend, roundingType: .defaultFiat(roundingMode: .down))?.description ?? "" : amountToSend.value.description
        previousFee = getDescription(for: previousFeeAmount, isFiat: isFiat)
    }

    private func updateFeeLabel(fee: Amount?, isFiat: Bool? = nil) {
        let isFiat = isFiat ?? isFiatCalculation
        if let fee = fee {
            additionalFee = getDescription(for: fee - previousFeeAmount, isFiat: isFiat)
        } else {
            additionalFee = getDescription(for: Amount.zeroCoin(for: blockchainNetwork.blockchain), isFiat: isFiat)
        }
    }

    private func updateAmount(isFeeIncluded: Bool, selectedFee: Amount?) {
        amountToSend = isFeeIncluded && selectedFee != nil ?
            transaction.amount + previousFeeAmount - selectedFee! :
            transaction.amount
        fillPreviousTxInfo(isFiat: isFiatCalculation)
    }

    private func fillTotalBlock(tx: BlockchainSdk.Transaction? = nil, isFiat: Bool) {
        guard let fee = tx?.fee.amount else {
            sendTotal = emptyValue
            sendTotalSubtitle = emptyValue
            return
        }

        let totalAmount = transaction.amount + fee
        var totalFiatAmount: Decimal?

        if let fiatAmount = getFiat(for: amountToSend, roundingType: .defaultFiat(roundingMode: .down)), let fiatFee = getFiat(for: fee, roundingType: .defaultFiat(roundingMode: .down)) {
            totalFiatAmount = fiatAmount + fiatFee
        }

        let totalFiatAmountFormatted = totalFiatAmount?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)

        if isFiat {
            sendTotal = totalFiatAmountFormatted ?? emptyValue
            sendTotalSubtitle = amountToSend.type == fee.type ?
                Localization.sendTotalSubtitleFormat(totalAmount.description) :
                Localization.sendTotalSubtitleAssetFormat(
                    amountToSend.description,
                    fee.description
                )
        } else {
            sendTotal = (amountToSend + fee).description
            sendTotalSubtitle = totalFiatAmountFormatted == nil ? emptyValue : Localization.sendTotalSubtitleFiatFormat(
                totalFiatAmountFormatted!,
                getFiatFormatted(for: fee, roundingType: .defaultFiat(roundingMode: .down))!
            )
        }
    }

    private func getFiatFormatted(for amount: Amount?, roundingType: AmountRoundingType) -> String? {
        return getFiat(for: amount, roundingType: roundingType)?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    private func getFiat(for amount: Amount?, roundingType: AmountRoundingType) -> Decimal? {
        if let amount = amount {
            guard let fiatValue = BalanceConverter().convertToFiat(value: amount.value, from: amount.currencySymbol) else {
                return nil
            }

            if fiatValue == 0 {
                return 0
            }

            switch roundingType {
            case .shortestFraction(let roundingMode):
                return SignificantFractionDigitRounder(roundingMode: roundingMode).round(value: fiatValue)
            case .default(let roundingMode, let scale):
                return max(fiatValue, Decimal(1) / pow(10, scale)).rounded(scale: scale, roundingMode: roundingMode)
            }
        }
        return nil
    }

    private func getCrypto(for amount: Amount?) -> Decimal? {
        guard let amount = amount else { return nil }

        return BalanceConverter()
            .convertFromFiat(value: amount.value, to: amount.currencySymbol)?
            .rounded(scale: amount.decimals)
    }
}

// MARK: - Navigation

extension PushTxViewModel {
    func openMail(with error: Error) {
        let emailDataCollector = PushScreenDataCollector(
            userWalletEmailData: userWalletModel.emailData,
            walletModel: walletModel,
            fee: newTransaction?.fee.amount,
            pushingFee: selectedFee?.amount,
            destination: transaction.destination,
            source: transaction.source,
            amount: transaction.amount,
            pushingTxHash: transaction.hash,
            lastError: error
        )

        let recipient = userWalletModel.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    func dismiss() {
        coordinator?.dismiss()
    }
}
