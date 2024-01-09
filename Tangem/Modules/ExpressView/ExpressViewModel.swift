//
//  ExpressViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError
import struct BlockchainSdk.Fee

final class ExpressViewModel: ObservableObject {
    // MARK: - ViewState

    // Main bubbles
    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var sendDecimalValue: DecimalNumberTextField.DecimalValue?
    @Published var isSwapButtonLoading: Bool = false
    @Published var isSwapButtonDisabled: Bool = false
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?

    // Warnings
    @Published var notificationInputs: [NotificationViewInput] = []

    // Provider
    @Published var providerState: ProviderState?

    // Fee
    var feeSectionItems: [FeeSectionItem] {
        var items: [FeeSectionItem] = []

        if let expressFeeRowViewModel {
            items.append(.fee(expressFeeRowViewModel))

            if let expressFeeFootnote {
                items.append(.footnote(expressFeeFootnote))
            }
        }

        return items
    }

    // Main button
    @Published var mainButtonIsLoading: Bool = false
    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var errorAlert: AlertBinder?

    @Published var legalText: NSAttributedString?

    // Private
    @Published private var expressFeeRowViewModel: ExpressFeeRowData?
    @Published private var expressFeeFootnote: String?

    // MARK: - Dependencies

    private let initialWallet: WalletModel
    private let userWalletModel: UserWalletModel
    private let swappingFeeFormatter: SwappingFeeFormatter
    private let balanceConverter: BalanceConverter
    private let balanceFormatter: BalanceFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let notificationManager: NotificationManager
    private let expressRepository: ExpressRepository
    private let interactor: ExpressInteractor
    private unowned let coordinator: ExpressRoutable

    // MARK: - Private

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common)
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        initialWallet: WalletModel,
        userWalletModel: UserWalletModel,
        swappingFeeFormatter: SwappingFeeFormatter,
        balanceConverter: BalanceConverter,
        balanceFormatter: BalanceFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        notificationManager: NotificationManager,
        expressRepository: ExpressRepository,
        interactor: ExpressInteractor,
        coordinator: ExpressRoutable
    ) {
        self.initialWallet = initialWallet
        self.userWalletModel = userWalletModel
        self.swappingFeeFormatter = swappingFeeFormatter
        self.balanceConverter = balanceConverter
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
        guard let sourceBalance = interactor.getSender().balanceValue else {
            return
        }

        sendDecimalValue = .external(sourceBalance)
        updateSendFiatValue(amount: sourceBalance)
        interactor.update(amount: sourceBalance)
    }

    func userDidTapSwapSwappingItemsButton() {
        Analytics.log(.swapButtonSwipe)
        interactor.swapPair()

        // If we have amount then we should round and update it with new decimalCount
        guard let amount = sendDecimalValue?.value else {
            return
        }

        let source = interactor.getSender()
        let roundedAmount = amount.rounded(scale: source.decimalCount, roundingMode: .down)
        sendDecimalValue = .external(roundedAmount)
        updateSendFiatValue(amount: roundedAmount)
        interactor.update(amount: roundedAmount)
    }

    func userDidTapChangeSourceButton() {
        coordinator.presentSwappingTokenList(swapDirection: .toDestination(initialWallet))
    }

    func userDidTapChangeDestinationButton() {
        coordinator.presentSwappingTokenList(swapDirection: .fromSource(initialWallet))
    }

    func didTapMainButton() {
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
}

// MARK: - Navigation

private extension ExpressViewModel {
    @MainActor
    func openSuccessView(sentTransactionData: SentExpressTransactionData) {
        coordinator.presentSuccessView(data: sentTransactionData)
    }

    func openApproveView() {
        guard case .permissionRequired = interactor.getState() else {
            return
        }

        coordinator.presentApproveView()
    }

    func openFeeSelectorView() {
        // If we have fees for choosing
        guard !interactor.getState().fees.isEmpty else {
            return
        }

        coordinator.presentFeeSelectorView()
    }

    func presentProviderSelectorView() {
        Analytics.log(.swapProviderClicked)
        coordinator.presentProviderSelectorView()
    }
}

// MARK: - View updates

private extension ExpressViewModel {
    func setupView() {
        sendCurrencyViewModel = SendCurrencyViewModel(
            maximumFractionDigits: interactor.getSender().decimalCount,
            canChangeCurrency: interactor.getSender().id != initialWallet.id,
            tokenIconState: .loading
        )

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            canChangeCurrency: interactor.getDestination()?.id != initialWallet.id,
            tokenIconState: .loading
        )
    }

    func bind() {
        $sendDecimalValue
            .removeDuplicates { $0?.value == $1?.value }
            // We skip the first nil value from the text field
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
            .filter { $0?.isInternal ?? true }
            .handleEvents(receiveOutput: { [weak self] amount in
                self?.interactor.cancelRefresh()
                self?.updateSendFiatValue(amount: amount?.value)
                self?.stopTimer()
            })
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.interactor.update(amount: amount?.value)

                if let amount, amount.value > 0 {
                    self?.startTimer()
                }
            }
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
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
            .sink { [weak self] pair in
                self?.updateSendView(wallet: pair.sender)
                self?.updateReceiveView(wallet: pair.destination)
            }
            .store(in: &bag)

        interactor.swappingPair
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

    // MARK: - Send view bubble

    func updateSendView(wallet: WalletModel) {
        updateSendCurrencyBalance(wallet: wallet)
        sendCurrencyViewModel?.maximumFractionDigits = wallet.decimalCount
        sendCurrencyViewModel?.canChangeCurrency = wallet.id != initialWallet.id
        sendCurrencyViewModel?.tokenIconState = mapToSwappingTokenIconViewModelState(wallet: wallet)

        updateSendFiatValue(amount: sendDecimalValue?.value)
    }

    func updateSendFiatValue(amount: Decimal?) {
        guard let amount = amount else {
            let formatted = balanceFormatter.formatFiatBalance(0)
            sendCurrencyViewModel?.update(fiatValue: .formatted(formatted))
            return
        }

        let tokenItem = interactor.getSender().tokenItem

        guard let currencyId = tokenItem.currencyId else {
            sendCurrencyViewModel?.update(fiatValue: .formatted(BalanceFormatter.defaultEmptyBalanceString))
            return
        }

        if let fiatValue = balanceConverter.convertToFiat(value: amount, from: currencyId) {
            let formatted = balanceFormatter.formatFiatBalance(fiatValue)
            sendCurrencyViewModel?.update(fiatValue: .formatted(formatted))
            return
        }

        sendCurrencyViewModel?.update(fiatValue: .loading)

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await viewModel.balanceConverter.convertToFiat(value: amount, from: currencyId)
            let formatted = viewModel.balanceFormatter.formatFiatBalance(fiatValue)
            try Task.checkCancellation()

            await runOnMain {
                viewModel.sendCurrencyViewModel?.update(fiatValue: .formatted(formatted))
            }
        }
    }

    func updateSendCurrencyBalance(wallet: WalletModel) {
        switch wallet.balanceValue {
        case .none:
            runTask(in: self) { viewModel in
                await runOnMain {
                    viewModel.sendCurrencyViewModel?.balance = .loading
                }

                _ = try await wallet.getBalance()
                await runOnMain {
                    viewModel.sendCurrencyViewModel?.balance = .formatted(wallet.balance)
                }
            }
        case .some:
            sendCurrencyViewModel?.balance = .formatted(wallet.balance)
        }
    }

    func updateSendCurrencyHeaderState(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .restriction(.notEnoughBalanceForSwapping, _),
             .restriction(.notEnoughAmountForFee, _):
            sendCurrencyViewModel?.headerState = .insufficientFunds
        default:
            sendCurrencyViewModel?.headerState = .header
        }
    }

    // MARK: - Receive view bubble

    func updateReceiveView(wallet: LoadingValue<WalletModel>) {
        switch wallet {
        case .loading:
            receiveCurrencyViewModel?.canChangeCurrency = false
            receiveCurrencyViewModel?.tokenIconState = .loading
            receiveCurrencyViewModel?.isAvailable = true
        case .loaded(let wallet):
            receiveCurrencyViewModel?.isAvailable = true
            receiveCurrencyViewModel?.canChangeCurrency = wallet.id != initialWallet.id
            receiveCurrencyViewModel?.tokenIconState = mapToSwappingTokenIconViewModelState(wallet: wallet)
            updateReceiveCurrencyBalance(wallet: wallet)

            let state = interactor.getState()
            switch state {
            case .loading:
                receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
                receiveCurrencyViewModel?.update(fiatAmountState: .loading)
            default:
                updateReceiveCurrencyValue(expectAmount: state.quote?.expectAmount)
                updateHighPricePercentLabel(quote: state.quote)
            }
        case .failedToLoad:
            receiveCurrencyViewModel?.canChangeCurrency = false
            receiveCurrencyViewModel?.tokenIconState = .notAvailable
            receiveCurrencyViewModel?.isAvailable = false
        }
    }

    func updateReceiveCurrencyBalance(wallet: WalletModel) {
        switch wallet.balanceValue {
        case .none:
            runTask(in: self) { viewModel in
                await runOnMain {
                    viewModel.receiveCurrencyViewModel?.balance = .loading
                }

                _ = try await wallet.getBalance()
                await runOnMain {
                    viewModel.receiveCurrencyViewModel?.balance = .formatted(wallet.balance)
                }
            }
        case .some:
            receiveCurrencyViewModel?.balance = .formatted(wallet.balance)
        }
    }

    func updateReceiveCurrencyValue(expectAmount: Decimal?) {
        guard let expectAmount else {
            receiveCurrencyViewModel?.update(cryptoAmountState: .formatted("0"))
            let formatted = balanceFormatter.formatFiatBalance(0)

            receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            return
        }

        let tokenItem = interactor.getDestination()?.tokenItem
        let decimals = tokenItem?.decimalCount ?? 8
        let formatter = DecimalNumberFormatter(maximumFractionDigits: decimals)
        let formatted = formatter.format(value: expectAmount)
        receiveCurrencyViewModel?.update(cryptoAmountState: .formatted(formatted))

        guard let currencyId = tokenItem?.currencyId else {
            let formatted = balanceFormatter.formatFiatBalance(0)
            receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            return
        }

        if let fiatValue = balanceConverter.convertToFiat(value: expectAmount, from: currencyId) {
            let formatted = balanceFormatter.formatFiatBalance(fiatValue)
            receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            return
        }

        receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        runTask(in: self) { [currencyId] viewModel in
            let fiatValue = try await viewModel.balanceConverter.convertToFiat(value: expectAmount, from: currencyId)
            let formatted = viewModel.balanceFormatter.formatFiatBalance(fiatValue)
            try Task.checkCancellation()

            await runOnMain {
                viewModel.receiveCurrencyViewModel?.update(fiatAmountState: .formatted(formatted))
            }
        }
    }

    func updateHighPricePercentLabel(quote: ExpressQuote?) {
        guard let fromAmount = quote?.fromAmount,
              let expectAmount = quote?.expectAmount,
              let sourceCurrencyId = interactor.getSender().tokenItem.currencyId,
              let destinationCurrencyId = interactor.getDestination()?.tokenItem.currencyId else {
            receiveCurrencyViewModel?.priceChangePercent = nil
            return
        }

        runTask(in: self) { viewModel in
            let priceImpactCalculator = HighPriceImpactCalculator(sourceCurrencyId: sourceCurrencyId, destinationCurrencyId: destinationCurrencyId)
            let result = try await priceImpactCalculator.isHighPriceImpact(
                converting: fromAmount,
                to: expectAmount
            )

            guard result.isHighPriceImpact else {
                await runOnMain {
                    viewModel.receiveCurrencyViewModel?.priceChangePercent = nil
                }
                return
            }

            let percentFormatter = PercentFormatter()
            let formatted = percentFormatter.expressRatePercentFormat(value: -result.lossesInPercents)
            await runOnMain {
                viewModel.receiveCurrencyViewModel?.priceChangePercent = formatted
            }
        }
    }

    // MARK: - Update for state

    func updateState(state: ExpressInteractor.ExpressInteractorState) {
        updateFeeValue(state: state)
        updateProviderView(state: state)
        updateMainButton(state: state)
        updateLegalText(state: state)
        updateSendCurrencyHeaderState(state: state)

        switch state {
        case .idle:
            isSwapButtonLoading = false
            stopTimer()

            updateReceiveCurrencyValue(expectAmount: 0)
            updateHighPricePercentLabel(quote: .none)

        case .loading(let type):
            isSwapButtonLoading = true

            // Turn on skeletons only for full update
            guard type == .full else { return }

            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.update(fiatAmountState: .loading)
            updateHighPricePercentLabel(quote: .none)

        case .restriction(let restriction, let quote):
            isSwapButtonLoading = false
            updateReceiveCurrencyValue(expectAmount: quote?.expectAmount)
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

            updateReceiveCurrencyValue(expectAmount: quote.expectAmount)
            updateHighPricePercentLabel(quote: quote)
        }
    }

    func updateProviderView(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .idle:
            providerState = .none
        case .loading(let type):
            if type == .full {
                providerState = .loading
            }
        default:
            runTask(in: self) { viewModel in
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

    func updateFeeValue(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .restriction(.notEnoughAmountForFee(let state), _):
            updateExpressFeeRowViewModel(fees: state.fees)
        case .previewCEX(let state, _):
            updateExpressFeeRowViewModel(fees: state.fees)
        case .readyToSwap(let state, _):
            updateExpressFeeRowViewModel(fees: state.fees)
        case .idle, .restriction, .loading(.full), .permissionRequired:
            // We have decided that will not give a choose for .permissionRequired state also
            expressFeeRowViewModel = nil
        case .loading(.refreshRates):
            break
        }
    }

    func updateExpressFeeRowViewModel(fees: [FeeOption: Fee]) {
        guard let fee = fees[interactor.getFeeOption()]?.amount.value else {
            expressFeeRowViewModel = nil
            return
        }

        let tokenItem = interactor.getSender().tokenItem
        let formattedFee = swappingFeeFormatter.format(fee: fee, tokenItem: tokenItem)

        var action: (() -> Void)?
        // If fee is one option then don't open selector
        if fees.count > 1 {
            action = weakify(self, forFunction: ExpressViewModel.openFeeSelectorView)
        }

        expressFeeRowViewModel = ExpressFeeRowData(title: Localization.commonFeeLabel, subtitle: formattedFee, action: action)
    }

    func updateMainButton(state: ExpressInteractor.ExpressInteractorState) {
        switch state {
        case .idle, .loading(type: .full):
            mainButtonState = .swap
            mainButtonIsEnabled = false
        case .loading(type: .refreshRates):
            // Do nothing
            break
        case .restriction(let type, _):
            switch type {
            case .hasPendingTransaction, .hasPendingApproveTransaction, .requiredRefresh, .notEnoughAmountForSwapping, .noDestinationTokens:
                mainButtonState = .swap
                mainButtonIsEnabled = false

            case .notEnoughAmountForFee, .notEnoughBalanceForSwapping:
                mainButtonState = .insufficientFunds
                mainButtonIsEnabled = false
            }

        case .permissionRequired:
            mainButtonState = .givePermission
            mainButtonIsEnabled = true

        case .readyToSwap, .previewCEX:
            mainButtonState = .swap
            mainButtonIsEnabled = true
        }
    }

    func updateLegalText(state _: ExpressInteractor.ExpressInteractorState) {
        runTask(in: self) { viewModel in
            let text = await viewModel.interactor.getSelectedProvider().flatMap { provider in
                viewModel.expressProviderFormatter.mapToLegalText(provider: provider.provider)
            }

            await runOnMain {
                viewModel.legalText = text
            }
        }
    }
}

// MARK: - Mapping

private extension ExpressViewModel {
    func mapToSwappingTokenIconViewModelState(wallet: WalletModel?) -> SwappingTokenIconView.State {
        guard let wallet = wallet else {
            return .loading
        }

        return .icon(
            TokenIconInfoBuilder().build(from: wallet.tokenItem, isCustom: wallet.isCustom),
            symbol: wallet.tokenItem.currencySymbol
        )
    }

    func mapToProviderRowViewModel() async -> ProviderRowViewModel? {
        guard let selectedProvider = await interactor.getSelectedProvider() else {
            return nil
        }

        // Setup additional expressFeeFootnote text if needed
        await runOnMain {
            switch selectedProvider.provider.type {
            case .cex:
                expressFeeFootnote = Localization.expressCexFeeExplanation
            case .dex:
                expressFeeFootnote = nil
            }
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

            return selectedProvider.isBest ? .bestRate : .none
        }()

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: selectedProvider.provider),
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
        runTask(in: self) { root in
            do {
                let sentTransactionData = try await root.interactor.send()

                try Task.checkCancellation()

                await root.openSuccessView(sentTransactionData: sentTransactionData)
            } catch TangemSdkError.userCancelled {
                root.restartTimer()
            } catch let error as ExpressAPIError {
                await runOnMain {
                    let message = Localization.expressErrorCode(error.errorCode.localizedDescription)
                    root.errorAlert = AlertBinder(title: Localization.commonError, message: message)
                }
            } catch {
                await runOnMain {
                    root.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }

            await runOnMain {
                root.mainButtonIsLoading = false
            }
        }
    }
}

// MARK: - Restrictions

extension ExpressViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard
            let notif = notificationInputs.first(where: { $0.id == id }),
            notif.settings.event is ExpressNotificationEvent
        else {
            return
        }

        switch action {
        case .refresh:
            interactor.refresh(type: .full)
        case .openNetworkCurrency:
            openNetworkCurrency()
        default: return
        }
    }

    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == .blockchain(initialWallet.tokenItem.blockchain) && $0.blockchainNetwork == initialWallet.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator.presentNetworkCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
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
    enum FeeSectionItem: Identifiable {
        var id: String {
            switch self {
            case .fee(let expressFeeRowData):
                return expressFeeRowData.id
            case .footnote(let string):
                return string
            }
        }

        case fee(ExpressFeeRowData)
        case footnote(String)
    }

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
                return Localization.swappingGivePermission
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

extension ExpressViewModel {
    private enum Constants {
        static let highPriceImpactWarningLimit: Decimal = 10
    }
}
