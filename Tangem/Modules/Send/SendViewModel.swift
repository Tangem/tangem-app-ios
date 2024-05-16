//
//  SendViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import AVFoundation

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stepAnimation: SendView.StepAnimation
    @Published var step: SendStep
    @Published var closeButtonDisabled = false
    @Published var showBackButton = false
    @Published var showTransactionButtons = false
    @Published var mainButtonType: SendMainButtonType
    @Published var mainButtonLoading: Bool = false
    @Published var mainButtonDisabled: Bool = false
    @Published var updatingFees = false
    @Published var alert: AlertBinder?

    var title: String? {
        step.name(for: sendStepParameters)
    }

    var hasSubtitle: Bool {
        subtitle != nil
    }

    var subtitle: String? {
        step.description(for: sendStepParameters)
    }

    var closeButtonColor: Color {
        closeButtonDisabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    var mainButtonTitle: String {
        mainButtonType.title
    }

    var mainButtonIcon: MainButton.Icon? {
        mainButtonType.icon
    }

    var showQRCodeButton: Bool {
        switch step {
        case .destination:
            return true
        case .amount, .fee, .summary, .finish:
            return false
        }
    }

    var shouldShowDismissAlert: Bool {
        if case .finish = step {
            return false
        }

        return didReachSummaryScreen
    }

    let sendAmountViewModel: SendAmountViewModel
    let sendDestinationViewModel: SendDestinationViewModel
    let sendFeeViewModel: SendFeeViewModel
    let sendSummaryViewModel: SendSummaryViewModel

    // MARK: - Dependencies

    private let sendModel: SendModel
    private let sendType: SendType
    private let steps: [SendStep]
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel
    private let emailDataProvider: EmailDataProvider
    private let walletInfo: SendWalletInfo
    private let notificationManager: CommonSendNotificationManager
    private let addressTextViewHeightModel: AddressTextViewHeightModel
    private let customFeeService: CustomFeeService?
    private let fiatCryptoAdapter: CommonSendFiatCryptoAdapter
    private let sendStepParameters: SendStep.Parameters
    private let keyboardVisibilityService: KeyboardVisibilityService

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []
    private var feeUpdateSubscription: AnyCancellable? = nil

    private var screenIdleStartTime: Date?
    private var currentPageAnimating: Bool? = nil
    private var didReachSummaryScreen: Bool

    private var currentStepValid: AnyPublisher<Bool, Never> {
        let inputFieldsValid = $step
            .flatMap { [weak self] step -> AnyPublisher<Bool, Never> in
                guard let self else {
                    return .just(output: true)
                }

                switch step {
                case .amount:
                    return sendModel.amountValid
                case .destination:
                    return sendModel.destinationValid
                case .fee:
                    return sendModel.feeValid
                case .summary:
                    return sendModel.transactionCreationError
                        .map { $0 == nil }
                        .eraseToAnyPublisher()
                case .finish:
                    return .just(output: true)
                }
            }

        let hasTransactionCreationError = Publishers.CombineLatest($step, sendModel.transactionCreationError)
            .map { step, error in
                guard let validationError = error as? ValidationError else { return false }
                return validationError.step == step
            }

        return Publishers.CombineLatest(inputFieldsValid, hasTransactionCreationError)
            .map { inputFieldsValid, hasTransactionCreationError in
                inputFieldsValid && !hasTransactionCreationError
            }
            .eraseToAnyPublisher()
    }

    init(
        walletName: String,
        walletModel: WalletModel,
        userWalletModel: UserWalletModel,
        transactionSigner: TransactionSigner,
        sendType: SendType,
        emailDataProvider: EmailDataProvider,
        canUseFiatCalculation: Bool,
        coordinator: SendRoutable
    ) {
        self.coordinator = coordinator
        self.sendType = sendType
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
        self.emailDataProvider = emailDataProvider

        let addressService = SendAddressServiceFactory(walletModel: walletModel).makeService()
        #warning("TODO: pass SendModel and NotificationManager as dependencies")
        sendModel = SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            addressService: addressService,
            sendType: sendType
        )

        let steps = sendType.steps
        guard let firstStep = steps.first else {
            fatalError("No steps provided for the send type")
        }
        self.steps = steps
        step = firstStep
        didReachSummaryScreen = (firstStep == .summary)
        mainButtonType = Self.mainButtonType(for: firstStep, didReachSummaryScreen: didReachSummaryScreen)
        stepAnimation = (firstStep == .summary) ? .moveAndFade : .slideForward

        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let cryptoIconURL: URL?
        if let tokenId = walletModel.tokenItem.id {
            cryptoIconURL = IconURLBuilder().tokenIconURL(id: tokenId)
        } else {
            cryptoIconURL = nil
        }

        let fiatIconURL = IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)

        walletInfo = SendWalletInfo(
            walletName: walletName,
            balanceValue: walletModel.balanceValue,
            balance: Localization.sendWalletBalanceFormat(walletModel.balance, walletModel.fiatBalance),
            blockchain: walletModel.blockchainNetwork.blockchain,
            currencyId: walletModel.tokenItem.currencyId,
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType),
            tokenIconInfo: tokenIconInfo,
            cryptoIconURL: cryptoIconURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: fiatIconURL,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            amountFractionDigits: walletModel.tokenItem.decimalCount,
            feeFractionDigits: walletModel.feeTokenItem.decimalCount,
            feeAmountType: walletModel.feeTokenItem.amountType,
            canUseFiatCalculation: canUseFiatCalculation
        )

        notificationManager = CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )

        let customFeeServiceFactory = CustomFeeServiceFactory(
            input: sendModel,
            output: sendModel,
            walletModel: walletModel
        )
        customFeeService = customFeeServiceFactory.makeService()

        fiatCryptoAdapter = CommonSendFiatCryptoAdapter(
            cryptoCurrencyId: walletInfo.currencyId,
            currencySymbol: walletInfo.cryptoCurrencyCode,
            decimals: walletInfo.amountFractionDigits
        )
        fiatCryptoAdapter.setAmount(sendType.predefinedAmount?.value)

        keyboardVisibilityService = KeyboardVisibilityService()

        sendStepParameters = SendStep.Parameters(currencyName: walletModel.tokenItem.name, walletName: walletInfo.walletName)

        let addressTextViewHeightModel = AddressTextViewHeightModel()
        self.addressTextViewHeightModel = addressTextViewHeightModel
        sendAmountViewModel = SendAmountViewModel(input: sendModel, fiatCryptoAdapter: fiatCryptoAdapter, walletInfo: walletInfo)
        sendDestinationViewModel = SendDestinationViewModel(input: sendModel, addressTextViewHeightModel: addressTextViewHeightModel)
        sendFeeViewModel = SendFeeViewModel(input: sendModel, notificationManager: notificationManager, customFeeService: customFeeService, walletInfo: walletInfo)
        sendSummaryViewModel = SendSummaryViewModel(input: sendModel, notificationManager: notificationManager, fiatCryptoValueProvider: fiatCryptoAdapter, addressTextViewHeightModel: addressTextViewHeightModel, walletInfo: walletInfo)

        fiatCryptoAdapter.setInput(sendAmountViewModel)
        fiatCryptoAdapter.setOutput(sendModel)

        sendFeeViewModel.router = coordinator
        sendSummaryViewModel.router = self

        notificationManager.setupManager(with: self)

        updateTransactionHistoryIfNeeded()

        bind()
    }

    func onCurrentPageAppear() {
        if currentPageAnimating != nil {
            currentPageAnimating = true
        }
    }

    func onCurrentPageDisappear() {
        currentPageAnimating = false
    }

    func dismiss() {
        Analytics.log(.sendButtonClose, params: [
            .source: step.analyticsSourceParameterValue,
            .fromSummary: .affirmativeOrNegative(for: didReachSummaryScreen),
            .valid: .affirmativeOrNegative(for: !mainButtonDisabled),
        ])

        if shouldShowDismissAlert {
            alert = SendAlertBuilder.makeDismissAlert { [coordinator] in
                coordinator?.dismiss()
            }
        } else {
            coordinator?.dismiss()
        }
    }

    func next() {
        // If we try to open another page mid-animation then the appropriate onAppear of the new page will not get called
        if currentPageAnimating ?? false {
            return
        }

        switch mainButtonType {
        case .next:
            guard let nextStep = nextStep(after: step) else {
                assertionFailure("Invalid step logic -- next")
                return
            }

            logNextStepAnalytics()

            let openingSummary = (nextStep == .summary)
            let stepAnimation: SendView.StepAnimation = openingSummary ? .moveAndFade : .slideForward

            let feeUpdatePolicy = FeeUpdatePolicy.fromTransition(currentStep: step, nextStep: nextStep)
            openStep(nextStep, stepAnimation: stepAnimation, feeUpdatePolicy: feeUpdatePolicy)
        case .continue:
            let nextStep = SendStep.summary
            let feeUpdatePolicy = FeeUpdatePolicy.fromTransition(currentStep: step, nextStep: nextStep)
            openStep(nextStep, stepAnimation: .moveAndFade, feeUpdatePolicy: feeUpdatePolicy)
        case .send:
            send()
        case .close:
            coordinator?.dismiss()
        }
    }

    func back() {
        guard let previousStep = previousStep(before: step) else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        openStep(previousStep, stepAnimation: .slideBackward, feeUpdatePolicy: nil)
    }

    func share() {
        guard let transactionURL = sendModel.transactionURL else {
            assertionFailure("WHY")
            return
        }

        Analytics.log(.sendButtonShare)
        coordinator?.openShareSheet(url: transactionURL)
    }

    func explore() {
        guard let transactionURL = sendModel.transactionURL else {
            assertionFailure("WHY")
            return
        }

        Analytics.log(.sendButtonExplore)
        coordinator?.openExplorer(url: transactionURL)
    }

    func scanQRCode() {
        let binding = Binding<String>(
            get: {
                ""
            },
            set: { [weak self] in
                self?.parseQRCode($0)
            }
        )

        let networkName = walletModel.blockchainNetwork.blockchain.displayName
        coordinator?.openQRScanner(with: binding, networkName: networkName)
    }

    func onSummaryAppear() {
        screenIdleStartTime = Date()
    }

    func onSummaryDisappear() {
        screenIdleStartTime = nil
    }

    private func bind() {
        sendModel.isSending
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest($updatingFees, sendModel.isSending)
            .map { updatingFees, isSending in
                updatingFees || isSending
            }
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest3(currentStepValid, $step, notificationManager.hasNotifications(with: .critical))
            .map { currentStepValid, step, hasCriticalNotifications in
                if !currentStepValid {
                    return true
                }

                if step == .summary, hasCriticalNotifications {
                    return true
                }

                return false
            }
            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        $updatingFees
            .sink { [weak self] updatingFees in
                self?.sendDestinationViewModel.setUserInputDisabled(updatingFees)
                self?.sendAmountViewModel.setUserInputDisabled(updatingFees)
            }
            .store(in: &bag)

        sendModel
            .destinationPublisher
            .sink { [weak self] destination in
                guard let self else { return }

                switch destination?.source {
                case .myWallet, .recentAddress:
                    next()
                default:
                    break
                }
            }
            .store(in: &bag)

        sendModel
            .sendError
            .sink { [weak self] error in
                guard let self, let error else { return }

                Analytics.log(event: .sendErrorTransactionRejected, params: [
                    .token: walletModel.tokenItem.currencySymbol,
                ])

                if case .noAccount(_, let amount) = (error as? WalletError) {
                    let amountFormatted = Amount(
                        with: walletModel.blockchainNetwork.blockchain,
                        type: walletModel.amountType,
                        value: amount
                    ).string()
                    let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
                    let message = Localization.sendNotificationInvalidReserveAmountText

                    alert = AlertBinder(title: title, message: message)
                } else {
                    let errorCode: String
                    let reason = String(error.localizedDescription.dropTrailingPeriod)
                    if let errorCodeProviding = error as? ErrorCodeProviding {
                        errorCode = "\(errorCodeProviding.errorCode)"
                    } else {
                        errorCode = "-"
                    }

                    alert = SendError(
                        title: Localization.sendAlertTransactionFailedTitle,
                        message: Localization.sendAlertTransactionFailedText(reason, errorCode),
                        error: error,
                        openMailAction: openMail
                    )
                    .alertBinder
                }
            }
            .store(in: &bag)

        sendModel
            .transactionFinished
            .removeDuplicates()
            .sink { [weak self] transactionFinished in
                guard let self, transactionFinished else { return }

                openFinishPage()

                if walletModel.isDemo {
                    let button = Alert.Button.default(Text(Localization.commonOk)) {
                        self.coordinator?.dismiss()
                    }
                    alert = AlertBuilder.makeAlert(title: "", message: Localization.alertDemoFeatureDisabled, primaryButton: button)
                } else {
                    logTransactionAnalytics()
                }

                if let address = sendModel.destinationText {
                    UserWalletFinder().addTokenItem(walletModel.tokenItem, for: address)
                }
            }
            .store(in: &bag)

        sendModel
            .destinationPublisher
            .sink { destination in
                guard let destination else { return }

                Analytics.logDestinationAddress(isAddressValid: destination.value != nil, source: destination.source)
            }
            .store(in: &bag)
    }

    private func logTransactionAnalytics() {
        let sourceValue: Analytics.ParameterValue
        switch sendType {
        case .send:
            sourceValue = .transactionSourceSend
        case .sell:
            sourceValue = .transactionSourceSell
        }
        Analytics.log(event: .transactionSent, params: [
            .source: sourceValue.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.blockchainNetwork.blockchain.displayName,
            .feeType: selectedFeeTypeAnalyticsParameter().rawValue,
            .memo: additionalFieldAnalyticsParameter().rawValue,
        ])

        Analytics.log(.sendSelectedCurrency, params: [
            .commonType: sendAmountViewModel.useFiatCalculation ? .selectedCurrencyApp : .token,
        ])
    }

    private func nextStep(after step: SendStep) -> SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex + 1) < steps.count
        else {
            return nil
        }

        return steps[currentStepIndex + 1]
    }

    private func previousStep(before step: SendStep) -> SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex - 1) >= 0
        else {
            return nil
        }

        return steps[currentStepIndex - 1]
    }

    private func openMail(with error: Error) {
        guard let transaction = sendModel.currentTransaction() else { return }

        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: sendModel.isFeeIncluded,
            lastError: error
        )
        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    private func showSummaryStepAlertIfNeeded(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool) -> Bool {
        if checkCustomFee {
            let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
            for event in events {
                switch event {
                case .customFeeTooLow:
                    Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
                        .token: walletModel.tokenItem.currencySymbol,
                    ])

                    alert = SendAlertBuilder.makeCustomFeeTooLowAlert { [weak self] in
                        self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false, feeUpdatePolicy: nil)
                    }

                    return true
                case .customFeeTooHigh(let orderOfMagnitude):
                    alert = SendAlertBuilder.makeCustomFeeTooHighAlert(orderOfMagnitude) { [weak self] in
                        self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false, feeUpdatePolicy: nil)
                    }

                    return true
                default:
                    break
                }
            }
        }

        return false
    }

    private static func mainButtonType(for step: SendStep, didReachSummaryScreen: Bool) -> SendMainButtonType {
        switch step {
        case .amount, .destination, .fee:
            if didReachSummaryScreen {
                return .continue
            } else {
                return .next
            }
        case .summary:
            return .send
        case .finish:
            return .close
        }
    }

    private func updateTransactionHistoryIfNeeded() {
        if walletModel.transactionHistoryNotLoaded {
            walletModel.updateTransactionsHistory()
                .sink()
                .store(in: &bag)
        }
    }

    private func updateFee(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool) {
        updatingFees = true

        feeUpdateSubscription = sendModel.updateFees()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.updatingFees = false

                guard case .failure = completion else { return }

                self?.alert = SendAlertBuilder.makeFeeRetryAlert {
                    self?.updateFee(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee)
                }
            } receiveValue: { [weak self] result in
                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, feeUpdatePolicy: nil)
            }
    }

    private func cancelUpdatingFee() {
        feeUpdateSubscription = nil
        updatingFees = false
    }

    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool = true, feeUpdatePolicy: FeeUpdatePolicy?) {
        if feeUpdatePolicy == .updateBeforeChangingStep {
            updateFee(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee)
            keyboardVisibilityService.hideKeyboard {
                // No matter how long it takes to get the fees when we try to open the step again we will check if the keyboard is open
                // If it's in the process of being hidden we will wait for it to finish
            }
            return
        }

        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
            keyboardVisibilityService.hideKeyboard { [weak self] in
                // Slight delay is needed, otherwise the animation of the keyboard will interfere with the page change
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, feeUpdatePolicy: feeUpdatePolicy)
                }
            }
            return
        }

        if case .summary = step {
            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
                return
            }

            didReachSummaryScreen = true

            sendSummaryViewModel.setupAnimations(previousStep: self.step)
        }

        // Gotta give some time to update animation variable
        self.stepAnimation = stepAnimation

        mainButtonType = Self.mainButtonType(for: step, didReachSummaryScreen: didReachSummaryScreen)

        DispatchQueue.main.async {
            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
            self.showTransactionButtons = self.sendModel.transactionURL != nil
            self.step = step

            if feeUpdatePolicy == .updateAfterChangingStep {
                self.feeUpdateSubscription = self.sendModel.updateFees()
                    .sink()
            }
        }
    }

    private func openFinishPage() {
        guard let sendFinishViewModel = SendFinishViewModel(input: sendModel, fiatCryptoValueProvider: fiatCryptoAdapter, addressTextViewHeightModel: addressTextViewHeightModel, feeTypeAnalyticsParameter: selectedFeeTypeAnalyticsParameter(), walletInfo: walletInfo) else {
            assertionFailure("WHY?")
            return
        }

        openStep(.finish(model: sendFinishViewModel), stepAnimation: .moveAndFade, feeUpdatePolicy: nil)
    }

    private func parseQRCode(_ code: String) {
        #warning("TODO: Add the necessary UI warnings")
        let parser = QRCodeParser(
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain,
            decimalCount: walletModel.decimalCount
        )

        guard let result = parser.parse(code) else {
            return
        }

        sendModel.setDestination(SendAddress(value: result.destination, source: .qrCode))
        sendModel.setAmount(result.amount)

        if let memo = result.memo {
            sendModel.setDestinationAdditionalField(memo)
        }
    }

    private func logNextStepAnalytics() {
        switch step {
        case .fee:
            Analytics.log(event: .sendFeeSelected, params: [.feeType: selectedFeeTypeAnalyticsParameter().rawValue])
        default:
            break
        }
    }

    private func selectedFeeTypeAnalyticsParameter() -> Analytics.ParameterValue {
        if sendModel.feeOptions.count == 1 {
            return .transactionFeeFixed
        }

        switch sendModel.selectedFeeOption {
        case .slow:
            return .transactionFeeMin
        case .market:
            return .transactionFeeNormal
        case .fast:
            return .transactionFeeMax
        case .custom:
            return .transactionFeeCustom
        }
    }

    private func additionalFieldAnalyticsParameter() -> Analytics.ParameterValue {
        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
        guard let additionalField = sendModel.additionalField else {
            return .null
        }

        return additionalField.1.isEmpty ? .empty : .full
    }

    // TODO: Andrey Fedorov - Re-use fee currency & redirect logic from Token Details & Send (IOS-5710)
    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

extension SendViewModel: SendSummaryRoutable {
    func openStep(_ step: SendStep) {
        guard self.step == .summary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        if let auxiliaryViewAnimatable = auxiliaryViewAnimatable(step) {
            auxiliaryViewAnimatable.setAnimatingAuxiliaryViewsOnAppear()
        }

        let feeUpdatePolicy = FeeUpdatePolicy.fromTransition(currentStep: self.step, nextStep: step)
        openStep(step, stepAnimation: .moveAndFade, feeUpdatePolicy: feeUpdatePolicy)
    }

    func send() {
        guard let screenIdleStartTime else { return }

        let feeValidityInterval: TimeInterval = 60
        let now = Date()
        if now.timeIntervalSince(screenIdleStartTime) <= feeValidityInterval {
            sendModel.send()
            return
        }

        sendModel.updateFees()
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.alert = SendAlertBuilder.makeFeeRetryAlert {
                        self?.send()
                    }
                }
            } receiveValue: { [weak self] result in
                self?.screenIdleStartTime = Date()

                if let oldFee = result.oldFee, result.newFee > oldFee {
                    self?.alert = AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
                } else {
                    self?.sendModel.send()
                }
            }
            .store(in: &bag)
    }

    private func auxiliaryViewAnimatable(_ step: SendStep) -> AuxiliaryViewAnimatable? {
        switch step {
        case .amount:
            return sendAmountViewModel
        case .destination:
            return sendDestinationViewModel
        case .fee:
            return sendFeeViewModel
        case .summary:
            return nil
        case .finish:
            return nil
        }
    }
}

extension SendViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            feeUpdateSubscription = sendModel.updateFees()
                .mapToVoid()
                .sink()
        case .openFeeCurrency:
            openNetworkCurrency()
        case .reduceAmountBy(let amount, _):
            reduceAmountBy(amount)
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        default:
            assertionFailure("Notification tap not handled")
        }
    }

    private func reduceAmountBy(_ amount: Decimal) {
        guard let currentAmount = sendModel.validatedAmountValue?.value else { return }

        var newAmount = currentAmount - amount
        if sendModel.isFeeIncluded, let feeValue = sendModel.feeValue?.amount.value {
            newAmount = newAmount - feeValue
        }

        fiatCryptoAdapter.setCrypto(newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        fiatCryptoAdapter.setCrypto(amount)
    }
}

// MARK: - SendStep

private extension SendStep {
    var updateFeeOnLeave: Bool {
        switch self {
        case .destination, .amount:
            return true
        case .fee, .summary, .finish:
            return false
        }
    }

    var isFinish: Bool {
        if case .finish = self {
            return true
        } else {
            return false
        }
    }

    var updateFeeOnOpen: Bool {
        switch self {
        case .fee:
            return true
        case .destination, .amount, .summary, .finish:
            return false
        }
    }

    var analyticsSourceParameterValue: Analytics.ParameterValue {
        switch self {
        case .amount:
            return .amount
        case .destination:
            return .address
        case .fee:
            return .fee
        case .summary:
            return .summary
        case .finish:
            return .finish
        }
    }
}

// MARK: - FeeUpdatePolicy

private extension SendViewModel {
    enum FeeUpdatePolicy {
        case updateBeforeChangingStep
        case updateAfterChangingStep
    }
}

extension SendViewModel.FeeUpdatePolicy {
    static func fromTransition(currentStep: SendStep, nextStep: SendStep) -> SendViewModel.FeeUpdatePolicy? {
        if nextStep == .summary, currentStep.updateFeeOnLeave {
            return .updateBeforeChangingStep
        } else if nextStep.updateFeeOnOpen {
            return .updateAfterChangingStep
        } else {
            return nil
        }
    }
}

// MARK: - ValidationError

private extension ValidationError {
    var step: SendStep? {
        switch self {
        case .invalidAmount, .balanceNotFound:
            // Shouldn't happen as we validate and cover amount errors separately, synchronously
            return nil
        case .amountExceedsBalance, .invalidFee, .feeExceedsBalance, .maximumUTXO, .reserve:
            return .fee
        case .dustAmount, .dustChange, .minimumBalance, .totalExceedsBalance:
            return .summary
        }
    }
}
