//
//  ExpressViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import UIKit
import enum TangemSdk.TangemSdkError
import struct BlockchainSdk.Fee
import TangemFoundation

final class ExpressViewModel: ObservableObject {
    // MARK: - ViewState

    // Main bubbles
    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var isSwapButtonLoading: Bool = false
    @Published var isSwapButtonDisabled: Bool = false
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var isMaxAmountButtonHidden: Bool = false

    // Warnings
    @Published var notificationInputs: [NotificationViewInput] = []

    // Provider
    @Published var providerState: ProviderState?

    // Fee
    @Published var expressFeeRowViewModel: ExpressFeeRowData?

    // Main button
    @Published var mainButtonIsLoading: Bool = false
    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var alert: AlertBinder?

    @Published var legalText: AttributedString?

    // MARK: - Dependencies

    private let initialWallet: WalletModel
    private let userWalletModel: UserWalletModel
    private let feeFormatter: FeeFormatter
    private let balanceFormatter: BalanceFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let notificationManager: NotificationManager
    private let expressRepository: ExpressRepository
    private let interactor: ExpressInteractor
    private weak var coordinator: ExpressRoutable?

    // MARK: - Private

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common)
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        initialWallet: WalletModel,
        userWalletModel: UserWalletModel,
        feeFormatter: FeeFormatter,
        balanceFormatter: BalanceFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        notificationManager: NotificationManager,
        expressRepository: ExpressRepository,
        interactor: ExpressInteractor,
        coordinator: ExpressRoutable
    ) {
        self.initialWallet = initialWallet
        self.userWalletModel = userWalletModel
        self.feeFormatter = feeFormatter
        self.balanceFormatter = balanceFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.notificationManager = notificationManager
        self.expressRepository = expressRepository
        self.interactor = interactor
        self.coordinator = coordinator

        Analytics.log(event: .swapScreenOpenedSwap, params: [.token: initialWallet.tokenItem.currencySymbol])
        setupView()
        bind()
    }

    func userDidTapMaxAmount() {
        let provider = interactor.getSender().availableBalanceProvider
        guard let sourceBalance = provider.balanceType.value else {
            return
        }

        updateSendDecimalValue(to: sourceBalance)
    }

    func userDidTapSwapSwappingItemsButton() {
        Analytics.log(.swapButtonSwipe)
        interactor.swapPair()
    }

    func userDidTapChangeSourceButton() {
        coordinator?.presentSwappingTokenList(swapDirection: .toDestination(initialWallet))
    }

    func userDidTapChangeDestinationButton() {
        coordinator?.presentSwappingTokenList(swapDirection: .fromSource(initialWallet))
    }

    func userDidTapPriceChangeInfoButton(isBigLoss: Bool) {
        TangemFoundation.runTask(in: self) { [weak self] viewModel in
            guard
                let selectedProvider = await viewModel.interactor.getSelectedProvider()?.provider,
                let tokenItemSymbol = viewModel.interactor.getDestination()?.tokenItem.currencySymbol
            else {
                return
            }

            let message: String? = { [weak self] in
                guard let self else { return nil }

                let slippage = formatDoubleToIntString(selectedProvider.slippage)

                switch selectedProvider.type {
                case .cex:
                    return formSlippageMessage(tokenItemSymbol: tokenItemSymbol, slippage: slippage)
                case .dex, .dexBridge:
                    return formSlippageMessage(
                        tokenItemSymbol: tokenItemSymbol,
                        slippage: slippage,
                        isBigLoss: isBigLoss
                    )
                case .onramp, .unknown:
                    return nil
                }
            }()

            guard let message else { return }

            await runOnMain {
                viewModel.alert = .init(title: "", message: message)
            }
        }
    }

    func didTapMainButton() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        switch mainButtonState {
        case .permitAndSwap:
            Analytics.log(.swapButtonPermitAndSwap)
        // TODO: https://tangem.atlassian.net/browse/IOS-2727
        case .swap:
            sendTransaction()
        case .givePermission:
            Analytics.log(.swapButtonGivePermission)
            openApproveView()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
        }
    }

    func didCloseApproveSheet() {
        restartTimer()
    }

    func didCloseFeeSelectorSheet() {
        restartTimer()
    }

    func didTapCloseButton() {
        coordinator?.closeSwappingView()
    }
}

// MARK: - Provider slippage message

private extension ExpressViewModel {
    func formSlippageMessage(tokenItemSymbol: String, slippage: String?) -> String {
        if let slippage {
            return Localization.swappingAlertCexDescriptionWithSlippage(tokenItemSymbol, "\(slippage)%")
        } else {
            return Localization.swappingAlertCexDescription(tokenItemSymbol)
        }
    }

    func formSlippageMessage(tokenItemSymbol: String, slippage: String?, isBigLoss: Bool) -> String {
        let swappingAlertDexDescription: String = {
            if let slippage {
                Localization.swappingAlertDexDescriptionWithSlippage("\(slippage)%")
            } else {
                Localization.swappingAlertDexDescription
            }
        }()

        if isBigLoss {
            return "\(Localization.swappingHighPriceImpactDescription)\n\n\(swappingAlertDexDescription)"
        }

        return swappingAlertDexDescription
    }

    func formatDoubleToIntString(_ value: Double?) -> String? {
        guard let value else { return nil }

        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(value)
        }
    }
}

// MARK: - Navigation

private extension ExpressViewModel {
    @MainActor
    func openSuccessView(sentTransactionData: SentExpressTransactionData) {
        coordinator?.presentSuccessView(data: sentTransactionData)
    }

    func openApproveView() {
        guard case .permissionRequired(let permissionRequired, _) = interactor.getState() else {
            return
        }

        TangemFoundation.runTask(in: self) { viewModel in
            guard let selectedProvider = await viewModel.interactor.getSelectedProvider()?.provider else {
                return
            }

            let selectedPolicy = permissionRequired.policy
            await runOnMain {
                viewModel.coordinator?.presentApproveView(provider: selectedProvider, selectedPolicy: selectedPolicy)
            }
        }
    }

    func openFeeSelectorView() {
        // If we have fees for choosing
        guard !interactor.getState().fees.isEmpty else {
            return
        }

        coordinator?.presentFeeSelectorView()
    }

    func presentProviderSelectorView() {
        Analytics.log(.swapProviderClicked)
        coordinator?.presentProviderSelectorView()
    }
}

// MARK: - View updates

private extension ExpressViewModel {
    func setupView() {
        sendCurrencyViewModel = SendCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingFromTitle),
                canChangeCurrency: interactor.getSender().id != initialWallet.id
            ),
            decimalNumberTextFieldViewModel: .init(maximumFractionDigits: interactor.getSender().decimalCount)
        )

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            expressCurrencyViewModel: .init(
                titleState: .text(Localization.swappingToTitle),
                canChangeCurrency: interactor.getDestination()?.id != initialWallet.id
            )
        )

        // First update
        updateSendView(wallet: interactor.getSender())
        updateReceiveView(wallet: interactor.getDestinationValue())
    }

    func bind() {
        sendCurrencyViewModel?
            .decimalNumberTextFieldViewModel
            .valuePublisher
            .handleEvents(receiveOutput: { [weak self] amount in
                self?.interactor.cancelRefresh()
                self?.updateSendFiatValue(amount: amount)
                self?.stopTimer()
            })
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.interactor.update(amount: amount, by: .amountChange)

                if let amount, amount > 0 {
                    self?.startTimer()
                }
            }
            .store(in: &bag)

        // Creates a publisher that emits changes in the notification list
        // based on a provided filter that compares the previous and new values
        let makeNotificationPublisher = { [notificationManager] filter in
            notificationManager
                .notificationPublisher
                .removeDuplicates()
                .scan(([NotificationViewInput](), [NotificationViewInput]())) { prev, new in
                    (prev.1, new)
                }
                .filter(filter)
                .map(\.1)
        }

        // Publisher for showing new notifications with a delay to prevent unwanted animations
        makeNotificationPublisher { $1.count >= $0.count }
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        // Publisher for immediate updates when notifications are removed (e.g., from 2 to 0 or 1)
        // to fix 'jumping' animation bug
        makeNotificationPublisher { $1.count < $0.count }
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateState(state: state)
            }
            .store(in: &bag)

        interactor.swappingPair
            .receive(on: DispatchQueue.main)
            .pairwise()
            .sink { [weak self] prev, pair in
                if pair.sender != prev.sender {
                    self?.updateSendView(wallet: pair.sender)
                }

                if pair.destination != prev.destination {
                    self?.updateReceiveView(wallet: pair.destination)
                }

                self?.updateMaxButtonVisibility(pair: pair)
            }
            .store(in: &bag)

        interactor.swappingPair
            .dropFirst()
            .withWeakCaptureOf(self)
            .asyncMap { viewModel, pair -> Bool in
                do {
                    if let destination = pair.destination.value {
                        let oppositePair = ExpressManagerSwappingPair(source: destination, destination: pair.sender)
                        let oppositeProviders = try await viewModel.expressRepository.getAvailableProviders(for: oppositePair)
                        return oppositeProviders.isEmpty
                    }
                    return true
                } catch {
                    return true
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSwapButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func updateSendDecimalValue(to value: Decimal) {
        sendCurrencyViewModel?.decimalNumberTextFieldViewModel.update(value: value)
        updateSendFiatValue(amount: value)
        interactor.update(amount: value, by: .amountChange)
    }

    // MARK: - Send view bubble

    func updateSendView(wallet: WalletModel) {
        sendCurrencyViewModel?.update(wallet: wallet, initialWalletId: initialWallet.id)

        // If we have amount then we should round and update it with new decimalCount
        guard let amount = sendCurrencyViewModel?.decimalNumberTextFieldViewModel.value else {
            updateSendFiatValue(amount: nil)
            return
        }

        let roundedAmount = amount.rounded(scale: wallet.decimalCount, roundingMode: .down)

        // Exclude unnecessary update
        guard roundedAmount != amount else {
            // update only fiat in case of another walletModel selection with another quote
            updateSendFiatValue(amount: amount)
            return
        }

        updateSendDecimalValue(to: roundedAmount)
    }

    func updateSendFiatValue(amount: Decimal?) {
        sendCurrencyViewModel?.updateSendFiatValue(amount: amount, tokenItem: interactor.getSender().tokenItem)
    }

    func updateSendCurrencyHeaderState(state: ExpressInteractor.State) {
        switch state {
        case .restriction(.notEnoughBalanceForSwapping, _):
            sendCurrencyViewModel?.expressCurrencyViewModel.update(titleState: .insufficientFunds)
        case .restriction(.notEnoughAmountForTxValue, _),
             .restriction(.notEnoughAmountForFee, _) where interactor.getSender().isFeeCurrency:
            sendCurrencyViewModel?.expressCurrencyViewModel.update(titleState: .insufficientFunds)
        case .restriction(.validationError(.minimumRestrictAmount(let minimumAmount), _), _):
            let errorText = Localization.transferMinAmountError(minimumAmount.string())
            sendCurrencyViewModel?.expressCurrencyViewModel.update(titleState: .error(errorText))
        default:
            sendCurrencyViewModel?.expressCurrencyViewModel.update(titleState: .text(Localization.swappingFromTitle))
        }
    }

    // MARK: - Receive view bubble

    func updateReceiveView(wallet: LoadingValue<WalletModel>) {
        receiveCurrencyViewModel?.update(wallet: wallet, initialWalletId: initialWallet.id)
    }

    func updateFiatValue(expectAmount: Decimal?) {
        receiveCurrencyViewModel?.updateFiatValue(
            expectAmount: expectAmount,
            tokenItem: interactor.getDestination()?.tokenItem
        )
    }

    func updateHighPricePercentLabel(quote: ExpressQuote?) {
        receiveCurrencyViewModel?.expressCurrencyViewModel.updateHighPricePercentLabel(
            quote: quote,
            sourceCurrencyId: interactor.getSender().tokenItem.currencyId,
            destinationCurrencyId: interactor.getDestination()?.tokenItem.currencyId
        )
    }

    // MARK: - Toolbar

    func updateMaxButtonVisibility(pair: ExpressInteractor.SwappingPair) {
        let sendingMainToken = pair.sender.isMainToken
        let isSameNetwork = pair.sender.blockchainNetwork == pair.destination.value?.blockchainNetwork

        isMaxAmountButtonHidden = sendingMainToken && isSameNetwork
    }

    // MARK: - Update for state

    func updateState(state: ExpressInteractor.State) {
        updateFeeValue(state: state)
        updateProviderView(state: state)
        updateMainButton(state: state)
        updateLegalText(state: state)
        updateSendCurrencyHeaderState(state: state)

        switch state {
        case .idle:
            isSwapButtonLoading = false
            stopTimer()

            updateFiatValue(expectAmount: 0)
            updateHighPricePercentLabel(quote: .none)

        case .loading(let type):
            isSwapButtonLoading = true

            // Turn on skeletons only for full update
            guard type == .full else { return }

            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.expressCurrencyViewModel.update(fiatAmountState: .loading)
            updateHighPricePercentLabel(quote: .none)

        case .restriction(let restriction, let quote):
            isSwapButtonLoading = false
            updateFiatValue(expectAmount: quote?.expectAmount)
            updateHighPricePercentLabel(quote: quote)

            // restart timer for pending approve transaction
            switch restriction {
            case .hasPendingApproveTransaction:
                restartTimer()
            default:
                stopTimer()
            }

        case .permissionRequired(_, let quote), .previewCEX(_, let quote), .readyToSwap(_, let quote):
            isSwapButtonLoading = false
            restartTimer()

            updateFiatValue(expectAmount: quote.expectAmount)
            updateHighPricePercentLabel(quote: quote)
        }
    }

    func updateProviderView(state: ExpressInteractor.State) {
        switch state {
        case .idle:
            providerState = .none
        case .loading(let type):
            if type == .full {
                providerState = .loading
            }
        default:
            TangemFoundation.runTask(in: self) { viewModel in
                let providerRowViewModel = await viewModel.mapToProviderRowViewModel()
                await runOnMain {
                    if let providerRowViewModel {
                        viewModel.providerState = .loaded(data: providerRowViewModel)
                    } else {
                        viewModel.providerState = .none
                    }
                }
            }
        }
    }

    func updateFeeValue(state: ExpressInteractor.State) {
        switch state {
        case .restriction(.notEnoughAmountForTxValue(let estimatedFee), _):
            // Signle estimated fee just for UI
            updateExpressFeeRowViewModel(fees: .loading)
        case .restriction(.notEnoughAmountForFee(let state), _):
            updateExpressFeeRowViewModel(fees: .success(state.fees))
        case .previewCEX(let state, _):
            updateExpressFeeRowViewModel(fees: .success(state.fees))
        case .readyToSwap(let state, _):
            updateExpressFeeRowViewModel(fees: .success(state.fees))
        case .loading(.fee):
            updateExpressFeeRowViewModel(fee: .loading, action: nil)
        case .idle, .restriction, .loading(.full), .permissionRequired:
            // We have decided that will not give a choose for .permissionRequired state also
            expressFeeRowViewModel = nil
        case .loading(.refreshRates):
            break
        }
    }

    func updateExpressFeeRowViewModel(fees: LoadingResult<ExpressInteractor.Fees, Never>) {
        switch fees {
        case .loading:
            updateExpressFeeRowViewModel(fee: .loading, action: nil)
        case .success(let fees):
            guard let fee = try? fees.selectedFee().amount.value else {
                expressFeeRowViewModel = nil
                return
            }

            var action: (() -> Void)?
            // If fee is one option then don't open selector
            if !fees.isFixed {
                action = weakify(self, forFunction: ExpressViewModel.openFeeSelectorView)
            }

            let tokenItem = interactor.getSender().feeTokenItem
            let formattedFee = feeFormatter.format(fee: fee, tokenItem: tokenItem)
            updateExpressFeeRowViewModel(fee: .loaded(text: formattedFee), action: action)
        }
    }

    func updateExpressFeeRowViewModel(fee: LoadableTextView.State, action: (() -> Void)?) {
        expressFeeRowViewModel = ExpressFeeRowData(
            title: Localization.commonNetworkFeeTitle,
            subtitle: fee,
            action: action
        )
    }

    func updateMainButton(state: ExpressInteractor.State) {
        switch state {
        case .idle, .loading(type: .full):
            mainButtonState = .swap
            mainButtonIsEnabled = false
        case .loading(type: .fee):
            mainButtonIsEnabled = false
        case .loading(type: .refreshRates):
            // Do nothing
            break
        case .restriction(let type, _):
            switch type {
            case .hasPendingTransaction,
                 .hasPendingApproveTransaction,
                 .requiredRefresh,
                 .tooSmallAmountForSwapping,
                 .tooBigAmountForSwapping,
                 .noDestinationTokens,
                 .validationError,
                 .notEnoughReceivedAmount:
                mainButtonState = .swap
            case .notEnoughBalanceForSwapping,
                 .notEnoughAmountForFee,
                 .notEnoughAmountForTxValue:
                mainButtonState = .insufficientFunds
            }

            mainButtonIsEnabled = false

        case .permissionRequired:
            mainButtonState = .givePermission
            mainButtonIsEnabled = true

        case .readyToSwap, .previewCEX:
            mainButtonState = .swap
            mainButtonIsEnabled = true
        }
    }

    func updateLegalText(state: ExpressInteractor.State) {
        switch state {
        case .loading(.refreshRates), .loading(.fee):
            break
        case .idle, .loading(.full):
            legalText = nil
        case .restriction, .permissionRequired, .previewCEX, .readyToSwap:
            TangemFoundation.runTask(in: self) { viewModel in
                let text = await viewModel.interactor.getSelectedProvider()?.provider.legalText(branch: .swap)
                await runOnMain {
                    viewModel.legalText = text
                }
            }
        }
    }
}

// MARK: - Mapping

private extension ExpressViewModel {
    func mapToProviderRowViewModel() async -> ProviderRowViewModel? {
        guard let selectedProvider = await interactor.getSelectedProvider() else {
            return nil
        }

        let state = await selectedProvider.getState()
        if state.isError {
            // Don't show a error provider
            return nil
        }

        let subtitle = expressProviderFormatter.mapToRateSubtitle(
            state: state,
            senderCurrencyCode: interactor.getSender().tokenItem.currencySymbol,
            destinationCurrencyCode: interactor.getDestination()?.tokenItem.currencySymbol,
            option: .exchangeRate
        )

        let badge: ProviderRowViewModel.Badge? = await {
            // We should show the "bestRate" badge only when we have a choose
            guard await interactor.getAllProviders().filter({ $0.isAvailable }).count > 1 else {
                return .none
            }

            if selectedProvider.provider.recommended == true {
                return .recommended
            }

            return selectedProvider.isBest ? .bestRate : .none
        }()

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: selectedProvider.provider),
            titleFormat: .name,
            isDisabled: false,
            badge: badge,
            subtitles: [subtitle],
            detailsType: .chevron
        ) { [weak self] in
            self?.presentProviderSelectorView()
        }
    }
}

// MARK: - Methods

private extension ExpressViewModel {
    func sendTransaction() {
        guard interactor.getState().isAvailableToSendTransaction else {
            return
        }

        stopTimer()
        mainButtonIsLoading = true
        TangemFoundation.runTask(in: self) { root in
            do {
                let sentTransactionData = try await root.interactor.send()

                try Task.checkCancellation()

                await root.openSuccessView(sentTransactionData: sentTransactionData)
            } catch TransactionDispatcherResult.Error.userCancelled {
                root.restartTimer()
            } catch let error as ExpressAPIError {
                await runOnMain {
                    let message = error.localizedMessage
                    root.alert = AlertBinder(title: Localization.commonError, message: message)
                }
            } catch {
                await runOnMain {
                    root.alert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }

            await runOnMain {
                root.mainButtonIsLoading = false
            }
        }
    }
}

// MARK: - NotificationTapDelegate

extension ExpressViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard
            let notification = notificationInputs.first(where: { $0.id == id }),
            let event = notification.settings.event as? ExpressNotificationEvent
        else {
            return
        }

        switch action {
        case .empty:
            break
        case .refresh:
            interactor.refresh(type: .full)
        case .openFeeCurrency:
            openFeeCurrency()
        case .reduceAmountBy(let amount, _):
            guard let value = sendCurrencyViewModel?.decimalNumberTextFieldViewModel.value else {
                AppLog.shared.debug("[Express] Couldn't find sendDecimalValue")
                return
            }

            updateSendDecimalValue(to: value - amount)
        case .reduceAmountTo(let amount, _):
            updateSendDecimalValue(to: amount)
        case .leaveAmount(let amount, _):
            guard let balance = try? interactor.getSender().getBalance() else {
                AppLog.shared.debug("[Express] Couldn't find sender balance")
                return
            }

            var targetValue = balance - amount
            if let feeValue = feeValue(from: event) {
                targetValue -= feeValue
            }

            updateSendDecimalValue(to: targetValue)
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refreshFee,
             .goToProvider,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .openLink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .swap,
             .support,
             .openCurrency,
             .seedSupportNo,
             .seedSupportYes:
            return
        }
    }
}

// MARK: - NotificationTapDelegate helpers

private extension ExpressViewModel {
    func openFeeCurrency() {
        let walletModels = userWalletModel.walletModelsManager.walletModels
        guard let feeCurrencyWalletModel = walletModels.first(where: {
            $0.tokenItem == interactor.getSender().feeTokenItem
        }) else {
            assertionFailure("Fee currency '\(initialWallet.feeTokenItem.name)' for currency '\(initialWallet.tokenItem.name)' not found")
            return
        }

        coordinator?.presentFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
    }

    func feeValue(from event: ExpressNotificationEvent) -> Decimal? {
        switch event {
        case .validationErrorEvent(_, let context) where context.isFeeCurrency:
            return context.feeValue
        case .permissionNeeded,
             .refreshRequired,
             .hasPendingTransaction,
             .hasPendingApproveTransaction,
             .notEnoughFeeForTokenTx,
             .tooSmallAmountToSwap,
             .tooBigAmountToSwap,
             .noDestinationTokens,
             .feeWillBeSubtractFromSendingAmount,
             .notEnoughReceivedAmountForReserve,
             .withdrawalNotificationEvent,
             .validationErrorEvent,
             .verificationRequired,
             .cexOperationFailed,
             .refunded:
            return nil
        }
    }
}

// MARK: - Timer

private extension ExpressViewModel {
    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func stopTimer() {
        AppLog.shared.debug("[Express] Stop timer")
        refreshDataTimerBag?.cancel()
        refreshDataTimer
            .connect()
            .cancel()
    }

    func startTimer() {
        AppLog.shared.debug("[Express] Start timer")
        refreshDataTimerBag = refreshDataTimer
            .autoconnect()
            .sink { [weak self] date in
                AppLog.shared.debug("[Express] Timer call autoupdate")
                self?.interactor.refresh(type: .refreshRates)
            }
    }
}

extension ExpressViewModel {
    enum ProviderState: Identifiable {
        var id: Int {
            switch self {
            case .loading:
                return "loading".hashValue
            case .loaded(let data):
                return data.id
            }
        }

        case loading
        case loaded(data: ProviderRowViewModel)
    }

    enum MainButtonState: Hashable, Identifiable {
        var id: Int { hashValue }

        case swap
        case insufficientFunds
        case givePermission
        case permitAndSwap

        var title: String {
            switch self {
            case .swap:
                return Localization.swappingSwapAction
            case .insufficientFunds:
                return Localization.swappingInsufficientFunds
            case .givePermission:
                return Localization.givePermissionTitle
            case .permitAndSwap:
                return Localization.swappingPermitAndSwap
            }
        }

        var icon: MainButton.Icon? {
            switch self {
            case .swap, .permitAndSwap:
                return .trailing(Assets.tangemIcon)
            case .givePermission, .insufficientFunds:
                return .none
            }
        }
    }
}
