//
//  SendViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk
import stellarsdk
import AVFoundation

class SendViewModel: ObservableObject {
    @Published var showCameraDeniedAlert = false

    // MARK: Input

    @Published var validatedClipboard: String? = nil
    @Published var destination: String = ""
    @Published var amountText: String = "0"

    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = false
    @Published var selectedFeeLevel: Int = 1
    @Published var maxAmountTapped: Bool = false
    @Published var fees: [Fee] = []

    @ObservedObject var warnings = WarningsContainer() {
        didSet {
            warnings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] in
                    withAnimation {
                        self?.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    // MARK: UI

    var shoudShowFeeSelector: Bool {
        walletModel.shoudShowFeeSelector
    }

    var shoudShowFeeIncludeSelector: Bool {
        if isSellingCrypto {
            return false
        }

        switch amountToSend.type {
        case .coin, .reserve:
            return true
        case .token:
            return !blockchainNetwork.blockchain.tokenTransactionFeePaidInNetworkCurrency
        }
    }

    var shouldShowNetworkBlock: Bool {
        shoudShowFeeSelector || shoudShowFeeIncludeSelector
    }

    var hasAdditionalInputFields: Bool {
        additionalInputFields != .none
    }

    var additionalInputFields: SendAdditionalFields {
        .fields(for: blockchainNetwork.blockchain)
    }

    var inputDecimalsCount: Int? {
        isFiatCalculation ? 2 : amountToSend.decimals
    }

    var isFiatConvertingAvailable: Bool {
        !isSellingCrypto && getFiat(for: amountToSend, roundingType: .defaultFiat(roundingMode: .down)) != nil
    }

    @Published var isNetworkFeeBlockOpen: Bool = false

    // MARK: Output

    @Published var destinationHint: TextHint? = nil
    @Published var amountHint: TextHint? = nil
    @Published var sendAmount: String = " "
    @Published var sendTotal: String = " "
    @Published var sendFee: String = " "
    @Published var sendTotalSubtitle: String = " "

    @Published var selectedFee: Fee? = nil
    @Published var transaction: BlockchainSdk.Transaction? = nil
    @Published var canFiatCalculation: Bool = true
    @Published var isFeeLoading: Bool = false

    var isSendEnabled: Bool {
        let hasDestinationErrorHint = destinationHint?.isError ?? false
        let hasAmountErrorHint = amountHint?.isError ?? false

        return !hasDestinationErrorHint && !hasAmountErrorHint && transaction != nil
    }

    // MARK: Additional input

    @Published var isAdditionalInputEnabled: Bool = false
    @Published var memo: String = ""
    @Published var memoHint: TextHint? = nil
    @Published var validatedMemoId: UInt64? = nil
    @Published var validatedMemo: String? = nil
    @Published var destinationTagStr: String = ""
    @Published var destinationTagHint: TextHint? = nil

    @Published var error: AlertBinder?

    let cardViewModel: CardViewModel

    var walletModel: WalletModel {
        let id = WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: amountToSend.type).id
        return cardViewModel.walletModelsManager.walletModels.first(where: { $0.id == id })!
    }

    var bag = Set<AnyCancellable>()

    var currencyUnit: String {
        return isFiatCalculation ? AppSettings.shared.selectedCurrencyCode : amountToSend.currencySymbol
    }

    var walletTotalBalanceDecimals: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        return isFiatCalculation ? getFiat(for: amount, roundingType: .defaultFiat(roundingMode: .down))?.description ?? ""
            : amount?.value.description ?? ""
    }

    var walletTotalBalanceFormatted: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        let value = getDescription(for: amount)
        return value
    }

    // MARK: Private

    @Published private var validatedDestination: String? = nil
    @Published private var validatedAmount: Amount? = nil

    let amountToSend: Amount

    private(set) var isSellingCrypto: Bool
    private var scannedQRCode: CurrentValueSubject<String?, Never> = .init(nil)

    @Published private var validatedXrpDestinationTag: UInt32? = nil

    private let feeRetrySubject = CurrentValueSubject<Void, Never>(())

    private var blockchainNetwork: BlockchainNetwork

    private var lastClipboardChangeCount: Int?
    private var lastDestinationAddressSource: Analytics.DestinationAddressSource?

    private unowned let coordinator: SendRoutable

    init(
        amountToSend: Amount,
        blockchainNetwork: BlockchainNetwork,
        cardViewModel: CardViewModel,
        coordinator: SendRoutable
    ) {
        self.blockchainNetwork = blockchainNetwork
        self.cardViewModel = cardViewModel
        self.amountToSend = amountToSend
        self.coordinator = coordinator
        isSellingCrypto = false
        fillTotalBlockWithDefaults()
        bind()
        setupWarnings()
    }

    deinit {
        AppLog.shared.debug("SendViewModel deinit")
    }

    convenience init(
        amountToSend: Amount,
        destination: String,
        blockchainNetwork: BlockchainNetwork,
        cardViewModel: CardViewModel,
        coordinator: SendRoutable
    ) {
        self.init(
            amountToSend: amountToSend,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardViewModel,
            coordinator: coordinator
        )
        isSellingCrypto = true
        self.destination = destination
        canFiatCalculation = false
        sendAmount = amountToSend.value.description
        amountText = sendAmount
    }

    private func getDescription(for amount: Amount?) -> String {
        if isFiatCalculation {
            return getFiatFormatted(for: amount, roundingType: .defaultFiat(roundingMode: .down)) ?? ""
        }

        return amount?.description ?? ""
    }

    private func fillTotalBlockWithDefaults() {
        let dummyAmount = Amount(with: amountToSend, value: 0)

        updateFee(amount: selectedFee?.amount)
        sendAmount = getDescription(for: dummyAmount)
        sendTotal = getDescription(for: dummyAmount)
        sendTotalSubtitle = " "
    }

    // MARK: - Subscriptions

    func bind() {
        bag = Set<AnyCancellable>()

        cardViewModel
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        $destination // destination validation
            .debounce(for: 1.0, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { [unowned self] newText in
                validateDestination(newText)
            }
            .store(in: &bag)

        $transaction // update total block
            .combineLatest($isFiatCalculation.uiPublisherWithFirst)
            .sink { [unowned self] tx, isFiatCalculation in
                if let tx = tx {
                    updateViewWith(transaction: tx)
                } else {
                    fillTotalBlockWithDefaults()
                }
            }
            .store(in: &bag)

        $isFiatCalculation
            .receive(on: DispatchQueue.global())
            .dropFirst()
            .sink { _ in
                Analytics.log(.buttonSwapCurrency)
            }.store(in: &bag)

        $isFiatCalculation // handle conversion
            .uiPublisher
            .filter { [unowned self] _ in amountText != "0" }
            .sink { [unowned self] value in
                guard let decimals = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else {
                    return
                }

                let amount = Amount(with: amountToSend, value: decimals)
                if let converted = value ? getFiat(for: amount, roundingType: .defaultFiat(roundingMode: .down))
                    : getCrypto(for: amount) {
                    amountText = converted.description
                } else {
                    amountText = "0"
                }
            }
            .store(in: &bag)

        // MARK: Amount

        $amountText
            .uiPublisher
            .combineLatest($isFiatCalculation.uiPublisherWithFirst)
            .removeDuplicates(by: { prev, current in
                prev.0 == current.0
            })
            .sink { [unowned self] newAmountString, isFiat in
                guard
                    let decimals = Decimal(string: newAmountString.replacingOccurrences(of: ",", with: ".")),
                    decimals > 0
                else {
                    amountHint = nil
                    validatedAmount = nil
                    return
                }

                let newAmountValue = isFiat ? getCrypto(for: Amount(with: amountToSend, value: decimals)) ?? 0 : decimals
                let newAmount = Amount(with: amountToSend, value: newAmountValue)

                do {
                    try walletModel.transactionCreator.validate(amount: newAmount)
                    amountHint = nil
                    validatedAmount = newAmount
                } catch {
                    amountHint = TextHint(isError: true, message: error.localizedDescription)
                    validatedAmount = nil
                }
            }
            .store(in: &bag)

        $validatedAmount // update fee
            .dropFirst()
            .compactMap { $0 }
            .combineLatest($validatedDestination.compactMap { $0 }, feeRetrySubject)
            .flatMap { [unowned self] amount, dest, _ -> AnyPublisher<[Fee], Never> in
                isFeeLoading = true
                return walletModel
                    .getFee(amount: amount, destination: dest)
                    .receive(on: DispatchQueue.main)
                    .catch { [unowned self] error in
                        AppLog.shared.error(error)
                        showLoadingFeeErrorAlert(error: error)
                        return Just([Fee]())
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .sink(receiveValue: { [unowned self] fees in
                isFeeLoading = false
                self.fees = fees
            })
            .store(in: &bag)

        $validatedAmount
            .combineLatest(
                $validatedDestination,
                $selectedFee,
                $isFeeIncluded
            )
            .sink { [unowned self] amount, destination, selectedFee, isFeeIncluded in
                guard let amount = amount, let destination = destination, let selectedFee else {
                    if (destination?.isEmpty == false) || destination == nil {
                        transaction = nil
                    }
                    return
                }

                do {
                    let tx = try walletModel.createTransaction(
                        amountToSend: isFeeIncluded ? amount - selectedFee.amount : amount,
                        fee: selectedFee,
                        destinationAddress: destination
                    )

                    DispatchQueue.main.async {
                        self.validateWithdrawal(tx, amount)
                    }

                    amountHint = nil
                    transaction = tx

                } catch {
                    amountHint = TextHint(isError: true, message: error.localizedDescription)
                    transaction = nil
                }
            }
            .store(in: &bag)

        $maxAmountTapped // handle max amount tap
            .dropFirst()
            .sink { [unowned self] _ in
                amountText = walletTotalBalanceDecimals
                withAnimation {
                    self.isFeeIncluded = true
                    self.isNetworkFeeBlockOpen = true
                }
            }
            .store(in: &bag)

        // MARK: Fee

        $fees // handle fee selection
            .combineLatest($selectedFeeLevel)
            .sink { [unowned self] fees, level in
                if fees.isEmpty {
                    selectedFee = nil
                } else {
                    selectedFee = fees.count > 1 ? fees[level] : fees.first!
                }
            }
            .store(in: &bag)

        $selectedFee // update fee label
            .uiPublisher
            .sink { [unowned self] newAmount in
                updateFee(amount: newAmount?.amount)
            }
            .store(in: &bag)

        // MARK: Memo + destination tag

        $destinationTagStr
            .uiPublisher
            .sink(receiveValue: { [unowned self] destTagStr in
                validatedXrpDestinationTag = nil
                destinationTagHint = nil

                if destTagStr.isEmpty { return }

                let tag = UInt32(destTagStr)
                validatedXrpDestinationTag = tag
                destinationTagHint = tag == nil ? TextHint(isError: true, message: Localization.sendExtrasErrorInvalidDestinationTag) : nil
            })
            .store(in: &bag)

        $memo
            .uiPublisher
            .sink(receiveValue: { [unowned self] memo in
                validatedMemoId = nil
                memoHint = nil
                validatedMemo = nil

                if memo.isEmpty { return }

                switch blockchainNetwork.blockchain {
                case .binance, .ton, .cosmos, .terraV1, .terraV2:
                    validatedMemo = memo
                case .stellar:
                    if let memoId = UInt64(memo) {
                        validatedMemoId = memoId
                    } else {
                        validatedMemo = memo
                    }
                default:
                    break
                }
            })
            .store(in: &bag)

        scannedQRCode
            .compactMap { $0 }
            .sink { [unowned self] qrCodeString in
                let withoutPrefix = qrCodeString.remove(contentsOf: walletModel.wallet.blockchain.qrPrefixes)
                let splitted = withoutPrefix.split(separator: "?")
                lastDestinationAddressSource = .qrCode
                destination = splitted.first.map { String($0) } ?? withoutPrefix

                if splitted.count > 1 {
                    let queryItems = splitted[1].lowercased().split(separator: "&")
                    for queryItem in queryItems {
                        if queryItem.contains("amount") {
                            amountText = queryItem.replacingOccurrences(of: "amount=", with: "")
                            break
                        }
                    }
                }
            }
            .store(in: &bag)
    }

    func onAppear() {
        Analytics.log(.sendScreenOpened)

        if #unavailable(iOS 16) {
            validateClipboard()
        }

        setupWarnings()
    }

    func onBecomingActive() {
        if #unavailable(iOS 16) {
            validateClipboard()
        }
    }

    // MARK: - Validation

    func validateClipboard() {
        if #available(iOS 16, *) {
            assertionFailure("Don't call this method, use PasteButton instead")
        }

        let clipboardChangeCount = UIPasteboard.general.changeCount
        if clipboardChangeCount == lastClipboardChangeCount {
            return
        }

        validatedClipboard = nil
        lastClipboardChangeCount = clipboardChangeCount

        guard let input = UIPasteboard.general.string else {
            return
        }

        if validateAddress(input) {
            validatedClipboard = input
        }
    }

    func validateAddress(_ address: String) -> Bool {
        let service = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        return service.validate(address) && !walletModel.wallet.addresses.contains(where: { $0.value == address })
    }

    func validateDestination(_ destination: String) {
        validatedDestination = nil
        destinationHint = nil
        isAdditionalInputEnabled = false

        if destination.isEmpty {
            return
        }

        let isAddressValid = validateAddress(destination)

        if isAddressValid {
            validatedDestination = destination
            setAdditionalInputVisibility(for: destination)
        } else {
            destinationHint = TextHint(
                isError: true,
                message: Localization.sendValidationInvalidAddress
            )
            setAdditionalInputVisibility(for: nil)
        }

        if let lastDestinationAddressSource { // ignore typing
            Analytics.logDestinationAddress(isAddressValid: isAddressValid, source: lastDestinationAddressSource)
            self.lastDestinationAddressSource = nil
        }
    }

    func validateWithdrawal(_ transaction: BlockchainSdk.Transaction, _ totalAmount: Amount) {
        guard
            let validator = walletModel.withdrawalValidator,
            let warning = validator.validate(transaction),
            error == nil
        else {
            return
        }

        let title = Text(Localization.commonWarning)
        let message = Text(warning.warningMessage)

        let reduceAmountButton = Alert.Button.default(
            Text(warning.reduceMessage),
            action: {
                let newAmount = totalAmount - warning.suggestedReduceAmount

                let newAmountValue: Decimal?
                if self.isFiatCalculation {
                    newAmountValue = self.getFiat(for: newAmount, roundingType: .defaultFiat(roundingMode: .down))
                } else {
                    newAmountValue = newAmount.value
                }
                self.amountText = newAmountValue?.description ?? "0"
            }
        )

        let alert: Alert
        if let ignoreMessage = warning.ignoreMessage {
            let ignoreButton = Alert.Button.cancel(Text(ignoreMessage))

            alert = Alert(
                title: title,
                message: message,
                primaryButton: reduceAmountButton,
                secondaryButton: ignoreButton
            )
        } else {
            alert = Alert(title: title, message: message, dismissButton: reduceAmountButton)
        }

        UIApplication.shared.endEditing()
        error = AlertBinder(alert: alert)
    }

    // MARK: Validation end -

    func pasteClipboardTapped() {
        Analytics.log(.buttonPaste)
        if let validatedClipboard = validatedClipboard {
            lastDestinationAddressSource = .pasteButton
            destination = validatedClipboard
        }
    }

    func pasteClipboardTapped(_ strings: [String]) {
        Analytics.log(.buttonPaste)

        if let string = strings.first {
            lastDestinationAddressSource = .pasteButton
            destination = string
        } else {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.error)
        }
    }

    func setAdditionalInputVisibility(for address: String?) {
        let isInputEnabled: Bool
        defer {
            withAnimation {
                isAdditionalInputEnabled = isInputEnabled
            }
        }

        guard let address = address else {
            isInputEnabled = false
            return
        }

        switch additionalInputFields {
        case .destinationTag:
            let xrpXAddress = try? XRPAddress.decodeXAddress(xAddress: address)
            isInputEnabled = xrpXAddress == nil
        case .memo:
            isInputEnabled = true
        default:
            isInputEnabled = false
        }
    }

    // MARK: - Send

    func send() {
        guard var tx = transaction else {
            return
        }

        if isAdditionalInputEnabled {
            switch blockchainNetwork.blockchain {
            case .binance:
                if let memo = validatedMemo {
                    tx.params = BinanceTransactionParams(memo: memo)
                }
            case .xrp:
                if let destinationTag = validatedXrpDestinationTag {
                    tx.params = XRPTransactionParams(destinationTag: destinationTag)
                }
            case .stellar:
                if let memoId = validatedMemoId {
                    tx.params = StellarTransactionParams(memo: .id(memoId))
                } else if let memoText = validatedMemo {
                    tx.params = StellarTransactionParams(memo: .text(memoText))
                }
            case .ton:
                if let memo = validatedMemo {
                    tx.params = TONTransactionParams(memo: memo)
                }
            case .cosmos, .terraV1, .terraV2:
                if let memo = validatedMemo {
                    tx.params = CosmosTransactionParams(memo: memo)
                }
            default:
                break
            }
        }

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()

        let isDemo = walletModel.isDemo

        walletModel.send(tx, signer: cardViewModel.signer)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                appDelegate.removeLoadingView()

                if case .failure(let error) = completion {
                    if error.toTangemSdkError().isUserCancelled {
                        return
                    }

                    AppLog.shared.error(error: error, params: [
                        .blockchain: walletModel.wallet.blockchain.displayName,
                        .action: Analytics.ParameterValue.sendTx.rawValue,
                    ])
                    self.error = SendError(error, openMailAction: openMail).alertBinder
                } else {
                    if !isDemo {
                        let sourceValue: Analytics.ParameterValue = isSellingCrypto ? .transactionSourceSell : .transactionSourceSend
                        Analytics.log(event: .transactionSent, params: [
                            .commonSource: sourceValue.rawValue,
                            .token: tx.amount.currencySymbol,
                            .blockchain: blockchainNetwork.blockchain.displayName,
                            .feeType: analyticsFeeType.rawValue,
                            .memo: retrieveAnalyticsMemoValue().rawValue,
                        ])

                        Analytics.log(.selectedCurrency, params: [
                            .commonType: isFiatCalculation ? .selectedCurrencyApp : .selectedCurrencyToken,
                        ])
                    }

                    let alert = AlertBuilder.makeSuccessAlert(
                        message: isDemo ? Localization.alertDemoFeatureDisabled
                            : Localization.sendTransactionSuccess,
                        okAction: close
                    )
                    error = alert
                }

            }, receiveValue: { _ in })
            .store(in: &bag)
    }

    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningView.WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        cardViewModel.warningsService.hideWarning(warning)
    }

    func openSystemSettings() {
        UIApplication.openSystemSettings()
    }

    func onPaste() {
        lastDestinationAddressSource = .pasteMenu
    }

    private func setupWarnings() {
        warnings = cardViewModel.warningsService.warnings(for: .send)
    }
}

// MARK: - Private

private extension SendViewModel {
    var analyticsFeeType: Analytics.ParameterValue {
        if shoudShowFeeSelector {
            let feeLevels: [Analytics.ParameterValue] = [
                .transactionFeeMin,
                .transactionFeeNormal,
                .transactionFeeMax,
            ]

            return feeLevels[selectedFeeLevel]
        } else {
            return .transactionFeeFixed
        }
    }

    func updateViewWith(transaction: BlockchainSdk.Transaction) {
        let totalAmount = transaction.amount + transaction.fee.amount
        let totalInFiatFormatted = totalAndFeeInFiatFormatted(
            from: transaction,
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )

        if isFiatCalculation {
            sendAmount = getFiatFormatted(for: transaction.amount, roundingType: .defaultFiat(roundingMode: .plain)) ?? ""
            sendTotal = totalInFiatFormatted.total

            if transaction.amount.type == transaction.fee.amount.type {
                sendTotalSubtitle = Localization.sendTotalSubtitleFormat(totalAmount.description)
            } else {
                sendTotalSubtitle = Localization.sendTotalSubtitleAssetFormat(
                    transaction.amount.description,
                    transaction.fee.description
                )
            }
        } else {
            sendAmount = transaction.amount.description
            sendTotal = (transaction.amount + transaction.fee.amount).description

            if totalInFiatFormatted.total.isEmpty {
                sendTotalSubtitle = " "
            } else {
                sendTotalSubtitle = Localization.sendTotalSubtitleFiatFormat(
                    totalInFiatFormatted.total,
                    totalInFiatFormatted.fee
                )
            }
        }

        updateFee(amount: transaction.fee.amount)
    }

    func totalAndFeeInFiatFormatted(from transaction: BlockchainSdk.Transaction, currencyCode: String) -> (total: String, fee: String) {
        guard let famount = getFiat(for: transaction.amount, roundingType: .shortestFraction(roundingMode: .plain)),
              let ffee = getFiat(for: transaction.fee.amount, roundingType: .shortestFraction(roundingMode: .plain)),
              let feeFormatted = getFiatFormatted(for: transaction.fee.amount, roundingType: .shortestFraction(roundingMode: .plain)) else {
            return (total: "", fee: "")
        }

        let totalAmount = famount + ffee
        let totalFiatFormatted = totalAmount.currencyFormatted(code: currencyCode)

        return (total: totalFiatFormatted, fee: feeFormatted)
    }

    /// If the amount will be nil then will be use dummy amount
    func updateFee(amount: Amount?) {
        sendFee = formattedFee(amount: amount ?? .zeroCoin(for: walletModel.wallet.blockchain))
    }

    func formattedFee(amount: Amount) -> String {
        let formatted: String

        if isFiatCalculation {
            formatted = getFiatFormatted(for: amount, roundingType: .defaultFiat(roundingMode: .plain)) ?? ""
        } else {
            formatted = amount.description
        }

        if amount.value > 0, walletModel.wallet.blockchain.isFeeApproximate(for: amountToSend.type) {
            return "< " + formatted
        }

        return formatted
    }

    func getFiatFormatted(for amount: Amount?, roundingType: AmountRoundingType) -> String? {
        return getFiat(for: amount, roundingType: roundingType)?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    func getFiat(for amount: Amount?, roundingType: AmountRoundingType) -> Decimal? {
        if let amount = amount {
            guard
                let currencyId = walletModel.tokenItem.currencyId,
                let fiatValue = BalanceConverter().convertToFiat(value: amount.value, from: currencyId)
            else {
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

    func getCrypto(for amount: Amount?) -> Decimal? {
        guard
            let amount = amount,
            let currencyId = walletModel.tokenItem.currencyId
        else {
            return nil
        }

        return BalanceConverter()
            .convertFromFiat(value: amount.value, to: currencyId)?
            .rounded(scale: amount.decimals)
    }

    func showLoadingFeeErrorAlert(error: Error) {
        let errorText: String
        if let ethError = error as? ETHError,
           case .gasRequiredExceedsAllowance = ethError {
            errorText = ethError.localizedDescription
        } else {
            errorText = WalletError.failedToGetFee.localizedDescription
        }

        let ok = Alert.Button.default(Text(Localization.commonOk))
        let retry = Alert.Button.default(Text(Localization.commonRetry)) { [unowned self] in
            feeRetrySubject.send()
        }
        let alert = Alert(title: Text(errorText), primaryButton: retry, secondaryButton: ok)
        self.error = AlertBinder(alert: alert)
    }

    func retrieveAnalyticsMemoValue() -> Analytics.ParameterValue {
        guard !additionalInputFields.isEmpty else {
            return .null
        }

        let hasEnteredData = validatedMemoId != nil || validatedMemo != nil || validatedXrpDestinationTag != nil
        return hasEnteredData ? .full : .empty
    }
}

// MARK: - Navigation

extension SendViewModel {
    func openMail(with error: Error) {
        guard let transaction else { return }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: cardViewModel.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: destination,
            amount: transaction.amount,
            isFeeIncluded: isFeeIncluded,
            lastError: error
        )

        let recipient = cardViewModel.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator.openMail(with: emailDataCollector, recipient: recipient)
    }

    func close() {
        coordinator.closeModule()
    }

    func openQRScanner() {
        Analytics.log(.buttonQRCode)
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            let binding = Binding<String>(
                get: { [weak self] in
                    self?.scannedQRCode.value ?? ""
                },
                set: { [weak self] in
                    self?.scannedQRCode.send($0)
                }
            )

            coordinator.openQRScanner(with: binding)
        }
    }
}
