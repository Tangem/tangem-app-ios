//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange
import TangemSdk
import SwiftUI

final class SwappingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var swapButtonIsLoading: Bool = false

    @Published var sendDecimalValue: DecimalNumberTextField.DecimalValue?
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var highPriceImpactWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var permissionInfoRowViewModel: DefaultWarningRowViewModel?

    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonState: MainButtonState = .swap
    @Published var errorAlert: AlertBinder?

    var informationSectionViewModels: [InformationSectionViewModel] {
        var viewModels: [InformationSectionViewModel] = []

        if let swappingFeeRowViewModel = swappingFeeRowViewModel {
            viewModels.append(.fee(swappingFeeRowViewModel))
        }

        if let feeWarningRowViewModel = feeWarningRowViewModel {
            viewModels.append(.warning(feeWarningRowViewModel))
        }

        if let feeInfoRowViewModel = feeInfoRowViewModel {
            viewModels.append(.warning(feeInfoRowViewModel))
        }

        return viewModels
    }

    @Published private var swappingFeeRowViewModel: SwappingFeeRowViewModel?
    @Published private var feeWarningRowViewModel: DefaultWarningRowViewModel?
    @Published private var feeInfoRowViewModel: DefaultWarningRowViewModel?

    // MARK: - Dependencies

    private let initialSourceCurrency: Currency
    private let exchangeManager: ExchangeManager
    private let swappingDestinationService: SwappingDestinationServicing
    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let transactionSender: TransactionSendable
    private let fiatRatesProvider: FiatRatesProviding
    private let userWalletModel: UserWalletModel
    private let currencyMapper: CurrencyMapping
    private let blockchainNetwork: BlockchainNetwork

    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private lazy var refreshDataTimer = Timer.publish(every: 1, on: .main, in: .common)
    // TODO: Remove this variable and refactor Task cancellation in DefaultExchangeManager
    private var pendingValidatingAmount: Decimal?
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        initialSourceCurrency: Currency,
        exchangeManager: ExchangeManager,
        swappingDestinationService: SwappingDestinationServicing,
        tokenIconURLBuilder: TokenIconURLBuilding,
        transactionSender: TransactionSendable,
        fiatRatesProvider: FiatRatesProviding,
        userWalletModel: UserWalletModel,
        currencyMapper: CurrencyMapping,
        blockchainNetwork: BlockchainNetwork,
        coordinator: SwappingRoutable
    ) {
        self.initialSourceCurrency = initialSourceCurrency
        self.exchangeManager = exchangeManager
        self.swappingDestinationService = swappingDestinationService
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.transactionSender = transactionSender
        self.fiatRatesProvider = fiatRatesProvider
        self.userWalletModel = userWalletModel
        self.currencyMapper = currencyMapper
        self.blockchainNetwork = blockchainNetwork
        self.coordinator = coordinator

        Analytics.log(event: .swapScreenOpenedSwap, params: [.token: initialSourceCurrency.symbol])
        setupView()
        bind()
        exchangeManager.setDelegate(self)
        loadDestinationIfNeeded()
    }

    func userDidTapMaxAmount() {
        let sourceBalance = exchangeManager.getExchangeItems().sourceBalance
        setupExternalSendValue(sourceBalance)
    }

    func userDidRequestChangeDestination(to currency: Currency) {
        var items = exchangeManager.getExchangeItems()

        if items.source == initialSourceCurrency {
            items.destination = currency
        } else if items.destination == initialSourceCurrency {
            items.source = currency
        }

        exchangeManager.update(exchangeItems: items)
        exchangeManager.refresh(type: .full)
    }

    func userDidTapSwapExchangeItemsButton() {
        Analytics.log(.swapButtonSwipe)
        var items = exchangeManager.getExchangeItems()

        guard let destination = items.destination else {
            return
        }

        let source = items.source

        items.source = destination
        items.destination = source
        exchangeManager.update(exchangeItems: items)

        // If amount have been set we'll should to round and update it with new decimalCount
        if let amount = sendDecimalValue?.value {
            let roundedAmount = amount.rounded(scale: items.source.decimalCount, roundingMode: .down)
            setupExternalSendValue(roundedAmount)

            exchangeManager.update(amount: roundedAmount)
        }
    }

    func userDidTapChangeCurrencyButton() {
        openTokenListView()
    }

    func userDidTapChangeDestinationButton() {
        Analytics.log(.swapReceiveTokenClicked)
        openTokenListView()
    }

    func didTapMainButton() {
        switch mainButtonState {
        case .permitAndSwap:
            Analytics.log(.swapButtonPermitAndSwap)
        // TODO: https://tangem.atlassian.net/browse/IOS-2727
        case .swap:
            swapItems()
        case .givePermission:
            Analytics.log(.swapButtonGivePermission)
            openPermissionView()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
        }
    }

    func didSendApproveTransaction(transactionInfo: ExchangeTransactionDataModel) {
        exchangeManager.didSendApprovingTransaction(exchangeTxData: transactionInfo)
    }

    func didClosePermissionSheet() {
        restartTimer()
    }

    func didTapWaringRefresh() {
        exchangeManager.refresh(type: .full)
    }

    private func setupExternalSendValue(_ amount: Decimal) {
        sendDecimalValue = .external(amount)
        pendingValidatingAmount = amount
    }
}

// MARK: - Navigation

private extension SwappingViewModel {
    func openTokenListView() {
        coordinator.presentSwappingTokenList(sourceCurrency: initialSourceCurrency)
    }

    func openSuccessView(
        result: SwappingResultDataModel,
        transactionModel: ExchangeTransactionDataModel,
        transactionID: String
    ) {
        let amount = transactionModel.sourceCurrency.convertFromWEI(value: transactionModel.sourceAmount)
        let source = CurrencyAmount(
            value: amount,
            currency: transactionModel.sourceCurrency
        )

        let result = CurrencyAmount(
            value: result.amount,
            currency: transactionModel.destinationCurrency
        )

        let inputModel = SwappingSuccessInputModel(
            sourceCurrencyAmount: source,
            resultCurrencyAmount: result,
            transactionID: transactionID
        )

        coordinator.presentSuccessView(inputModel: inputModel)
    }

    func openPermissionView() {
        let state = exchangeManager.getAvailabilityState()

        guard case .available(let result, let info) = state,
              result.isPermissionRequired,
              fiatRatesProvider.hasRates(for: info.sourceBlockchain) else {
            // If we don't have enough data disable button and refresh()
            mainButtonIsEnabled = false
            exchangeManager.refresh(type: .full)

            return
        }

        runTask(in: self) { obj in
            let fiatFee = try await obj.fiatRatesProvider.getFiat(for: info.sourceBlockchain, amount: info.fee)
            let inputModel = SwappingPermissionInputModel(
                fiatFee: fiatFee,
                transactionInfo: info
            )

            obj.stopTimer()

            await runOnMain {
                obj.coordinator.presentPermissionView(
                    inputModel: inputModel,
                    transactionSender: obj.transactionSender
                )
            }
        }
    }
}

// MARK: - ExchangeManagerDelegate

extension SwappingViewModel: ExchangeManagerDelegate {
    func exchangeManager(_ manager: ExchangeManager, didUpdate exchangeItems: ExchangeItems) {
        DispatchQueue.main.async {
            self.updateView(exchangeItems: exchangeItems)
        }
    }

    func exchangeManager(_ manager: ExchangeManager, didUpdate availabilityState: ExchangeAvailabilityState) {
        DispatchQueue.main.async {
            self.updateState(state: availabilityState)
        }
    }
}

// MARK: - View updates

private extension SwappingViewModel {
    func resetViews() {
        refreshWarningRowViewModel = nil
        feeWarningRowViewModel = nil
        permissionInfoRowViewModel = nil
        highPriceImpactWarningRowViewModel = nil
        swapButtonIsLoading = false
    }

    func updateView(exchangeItems: ExchangeItems) {
        updateSendView(exchangeItems: exchangeItems)
        updateReceiveView(exchangeItems: exchangeItems)
    }

    func updateSendView(exchangeItems: ExchangeItems) {
        let source = exchangeItems.source

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: .loaded(exchangeItems.sourceBalance),
            fiatValue: .loading,
            maximumFractionDigits: source.decimalCount,
            canChangeCurrency: source != initialSourceCurrency,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: source)
        )

        updateSendFiatValue()
    }

    func updateSendFiatValue() {
        guard let decimalValue = sendDecimalValue?.value else {
            sendCurrencyViewModel?.update(fiatValue: .loaded(0))
            return
        }

        let source = exchangeManager.getExchangeItems().source
        if !fiatRatesProvider.hasRates(for: source) {
            sendCurrencyViewModel?.update(fiatValue: .loading)
        }

        Task {
            let fiatValue = try await fiatRatesProvider.getFiat(for: source, amount: decimalValue)
            await runOnMain {
                sendCurrencyViewModel?.update(fiatValue: .loaded(fiatValue))
            }
        }
    }

    func updateReceiveView(exchangeItems: ExchangeItems) {
        let destination = exchangeItems.destination

        let cryptoAmountState: ReceiveCurrencyViewModel.State
        let fiatAmountState: ReceiveCurrencyViewModel.State

        switch exchangeManager.getAvailabilityState() {
        case .idle, .requiredRefresh:
            cryptoAmountState = .loaded(0)
            fiatAmountState = .loaded(0)
        case .loading:
            cryptoAmountState = .loading
            fiatAmountState = .loading
        case .preview(let result):
            cryptoAmountState = .loaded(result.expectedAmount)
            fiatAmountState = .loading
            updateReceiveCurrencyValue(value: result.expectedAmount)
        case .available(let result, _):
            cryptoAmountState = .loaded(result.amount)
            fiatAmountState = .loading
            updateReceiveCurrencyValue(value: result.amount)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            balance: exchangeItems.destinationBalance,
            canChangeCurrency: destination != initialSourceCurrency,
            cryptoAmountState: cryptoAmountState,
            fiatAmountState: fiatAmountState,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: destination)
        )
    }

    func updateState(state: ExchangeAvailabilityState) {
        updateFeeValue(state: state)
        updateMainButton(state: state)

        switch state {
        case .idle:
            resetViews()

            receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(0))
            receiveCurrencyViewModel?.update(fiatAmountState: .loaded(0))

        case .loading(let type):
            swapButtonIsLoading = true

            // Turn on skeletons only for full update
            guard type == .full else { return }

            refreshWarningRowViewModel?.update(rightView: .loader)
            receiveCurrencyViewModel?.update(cryptoAmountState: .loading)
            receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        case .preview(let result):
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            swapButtonIsLoading = false

            restartTimer()
            updateReceiveCurrencyValue(value: result.expectedAmount)
            updateRequiredPermission(isPermissionRequired: result.isPermissionRequired)
            updatePendingApprovingTransaction(hasPendingTransaction: result.hasPendingTransaction)

        case .available(let result, _):
            refreshWarningRowViewModel = nil
            swapButtonIsLoading = false

            restartTimer()
            updateReceiveCurrencyValue(value: result.amount)
            updateRequiredPermission(isPermissionRequired: result.isPermissionRequired)
            updateEnoughAmountForFee(isEnoughAmountForFee: result.isEnoughAmountForFee)

        case .requiredRefresh(let error):
            swapButtonIsLoading = false

            stopTimer()
            receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(0))
            receiveCurrencyViewModel?.update(fiatAmountState: .loaded(0))

            processingError(error: error)
        }
    }

    func updateReceiveCurrencyValue(value: Decimal) {
        receiveCurrencyViewModel?.update(cryptoAmountState: .loaded(value))

        guard let destination = exchangeManager.getExchangeItems().destination else { return }
        receiveCurrencyViewModel?.update(fiatAmountState: .loading)

        Task {
            let fiatValue = try await fiatRatesProvider.getFiat(for: destination, amount: value)
            await runOnMain {
                receiveCurrencyViewModel?.update(fiatAmountState: .loaded(fiatValue))
            }
            try await checkForHighPriceImpact(destinationFiatAmount: fiatValue)
        }
    }

    func updateRequiredPermission(isPermissionRequired: Bool) {
        if isPermissionRequired {
            permissionInfoRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingGivePermission,
                subtitle: Localization.swappingPermissionSubheader(exchangeManager.getExchangeItems().source.symbol),
                leftView: .icon(Assets.swappingLock)
            )
        } else {
            permissionInfoRowViewModel = nil
        }
    }

    func updatePendingApprovingTransaction(hasPendingTransaction: Bool) {
        if hasPendingTransaction {
            permissionInfoRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingPendingTransactionTitle,
                subtitle: Localization.swappingPendingTransactionSubtitle,
                leftView: .loader
            )
        } else {
            permissionInfoRowViewModel = nil
        }
    }

    func updateEnoughAmountForFee(isEnoughAmountForFee: Bool) {
        if isEnoughAmountForFee {
            feeWarningRowViewModel = nil
        } else {
            let sourceBlockchain = exchangeManager.getExchangeItems().source.blockchain
            feeWarningRowViewModel = DefaultWarningRowViewModel(
                subtitle: Localization.swappingNotEnoughFundsForFee(sourceBlockchain.symbol, sourceBlockchain.symbol),
                leftView: .icon(Assets.attention)
            )
        }
    }

    func updateFeeValue(state: ExchangeAvailabilityState) {
        switch state {
        case .idle, .requiredRefresh, .preview:
            swappingFeeRowViewModel?.update(state: .idle)
        case .loading(let type):
            if type == .full {
                swappingFeeRowViewModel?.update(state: .loading)
            }
        case .available(_, let info):
            let source = exchangeManager.getExchangeItems().source

            Task {
                let fiatFee = try await fiatRatesProvider.getFiat(for: info.sourceBlockchain, amount: info.fee)
                let code = await AppSettings.shared.selectedCurrencyCode

                await runOnMain {
                    swappingFeeRowViewModel?.update(
                        state: .fee(
                            fee: info.fee.groupedFormatted(),
                            symbol: source.blockchain.symbol,
                            fiat: fiatFee.currencyFormatted(code: code)
                        )
                    )
                }
            }
        }
    }

    func updateMainButton(state: ExchangeAvailabilityState) {
        switch state {
        case .idle:
            mainButtonIsEnabled = false
            mainButtonState = .swap
        case .loading(let type):
            if type == .full {
                mainButtonIsEnabled = false
            }
        case .requiredRefresh:
            mainButtonIsEnabled = false
        case .preview(let preview):
            mainButtonIsEnabled = preview.isEnoughAmountForExchange && !preview.hasPendingTransaction

            if !preview.isEnoughAmountForExchange {
                mainButtonState = .insufficientFunds
            } else if preview.hasPendingTransaction {
                mainButtonState = .swap
            } else if preview.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }

        case .available(let model, _):
            mainButtonIsEnabled = model.isEnoughAmountForExchange && model.isEnoughAmountForFee

            if !model.isEnoughAmountForExchange {
                mainButtonState = .insufficientFunds
            } else if model.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }
        }
    }

    func checkForHighPriceImpact(destinationFiatAmount: Decimal) async throws {
        guard
            let sendDecimalValue = sendDecimalValue?.value,
            pendingValidatingAmount?.isEqual(to: sendDecimalValue) ?? false
        else {
            // Current send decimal value was changed during old update. We can ignore this check
            return
        }

        if sendDecimalValue.isZero {
            pendingValidatingAmount = nil
            // No need to calculate price impact with zero input
            await runOnMain {
                highPriceImpactWarningRowViewModel = nil
            }
            return
        }

        let sourceFiatAmount = try await fiatRatesProvider.getFiat(
            for: exchangeManager.getExchangeItems().source,
            amount: sendDecimalValue
        )

        let lossesInPercents = (1 - destinationFiatAmount / sourceFiatAmount) * 100

        await runOnMain {
            if lossesInPercents >= Constants.highPriceImpactWarningLimit {
                highPriceImpactWarningRowViewModel = DefaultWarningRowViewModel(
                    title: Localization.swappingHighPriceImpact,
                    subtitle: Localization.swappingHighPriceImpactDescription,
                    leftView: .icon(Assets.warningIcon)
                )
            } else {
                highPriceImpactWarningRowViewModel = nil
            }
            pendingValidatingAmount = nil
        }
    }

    func setupView() {
        updateState(state: .idle)
        updateView(exchangeItems: exchangeManager.getExchangeItems())

        swappingFeeRowViewModel = SwappingFeeRowViewModel(state: .idle) { [weak self] in
            Binding<Bool> {
                self?.feeInfoRowViewModel != nil
            } set: { isOpen in
                UIApplication.shared.endEditing()

                if isOpen {
                    let percentFee = self?.exchangeManager.getReferrerAccount()?.fee ?? 0
                    let formattedFee = "\(percentFee.groupedFormatted())%"
                    self?.feeInfoRowViewModel = DefaultWarningRowViewModel(
                        subtitle: Localization.swappingTangemFeeDisclaimer(formattedFee),
                        leftView: .icon(Assets.heartMini)
                    )
                } else {
                    self?.feeInfoRowViewModel = nil
                }
            }
        }
    }

    func bind() {
        $sendDecimalValue
            .dropFirst()
            // If value == nil anyway continue chain
            .filter { $0?.isInternal ?? true }
            .map { $0?.value }
            .removeDuplicates()
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                // TODO: Refactor send decimal value storage logic
                // Currently sendDecimalValue is updating directly from UI
                // but requesting update in exchange manager with 1 second delay.
                // So when all necessary information already loaded in exchange manager
                // we will face wrong send decimal value while checking high price impact.
                self?.pendingValidatingAmount = amount
                self?.resetViews()
                self?.exchangeManager.update(amount: amount)
                self?.updateSendFiatValue()
            }
            .store(in: &bag)
    }

    func loadDestinationIfNeeded() {
        guard exchangeManager.getExchangeItems().destination == nil else {
            AppLog.shared.debug("Exchange item destination has already set")
            return
        }

        Task {
            var items = exchangeManager.getExchangeItems()

            do {
                items.destination = try await swappingDestinationService.getDestination(source: items.source)
                exchangeManager.update(exchangeItems: items)
                exchangeManager.refresh(type: .full)
            } catch {
                AppLog.shared.debug("Destination load handle error")
                AppLog.shared.error(error)
                items.destination = nil
            }
        }
    }

    func mapToSwappingTokenIconViewModel(currency: Currency?) -> SwappingTokenIconViewModel {
        guard let currency = currency else {
            return SwappingTokenIconViewModel(state: .loading)
        }

        switch currency.currencyType {
        case .coin:
            return SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: tokenIconURLBuilder.iconURL(id: currency.blockchain.id, size: .large),
                    symbol: currency.symbol
                )
            )
        case .token:
            return SwappingTokenIconViewModel(
                state: .loaded(
                    imageURL: tokenIconURLBuilder.iconURL(id: currency.id, size: .large),
                    networkURL: tokenIconURLBuilder.iconURL(id: currency.blockchain.id, size: .small),
                    symbol: currency.symbol
                )
            )
        }
    }

    func swapItems() {
        let state = exchangeManager.getAvailabilityState()
        guard case .available(let result, let info) = state else {
            return
        }

        stopTimer()
        Analytics.log(
            event: .swapButtonSwap,
            params: [
                .sendToken: info.sourceCurrency.symbol,
                .receiveToken: info.destinationCurrency.symbol,
            ]
        )

        Task {
            do {
                let sendResult = try await transactionSender.sendTransaction(info)
                addDestinationTokenToUserWalletList()
                exchangeManager.didSendSwapTransaction(exchangeTxData: info)

                Analytics.log(.transactionSentBasic, params: [.commonSource: .transactionSourceSwap])

                await runOnMain {
                    openSuccessView(result: result, transactionModel: info, transactionID: sendResult.hash)
                }
            } catch TangemSdkError.userCancelled {
                restartTimer()
            } catch {
                await runOnMain {
                    errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }

    func processingError(error: Error) {
        AppLog.shared.debug("DefaultExchangeManager catch error: ")
        AppLog.shared.error(error)

        switch error {
        case let error as ExchangeManagerError:
            switch error {
            case .walletAddressNotFound, .destinationNotFound, .amountNotFound:
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        case let error as ExchangeProviderError:
            switch error {
            case .requestError(let error):
                updateRefreshWarningRowViewModel(message: error.detailedError.localizedDescription)
            case .oneInchError(let error):
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            case .decodingError(let error):
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        default:
            updateRefreshWarningRowViewModel(message: Localization.commonError)
        }
    }

    func updateRefreshWarningRowViewModel(message: String) {
        refreshWarningRowViewModel = DefaultWarningRowViewModel(
            subtitle: Localization.swappingErrorWrapper(message.capitalizingFirstLetter()),
            leftView: .icon(Assets.attention),
            rightView: .icon(Assets.refreshWarningIcon)
        ) { [weak self] in
            self?.didTapWaringRefresh()
        }
    }

    func addDestinationTokenToUserWalletList() {
        guard let destination = exchangeManager.getExchangeItems().destination,
              let token = currencyMapper.mapToToken(currency: destination) else {
            return
        }

        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
        userWalletModel.append(entries: [entry])
        userWalletModel.updateWalletModels()
    }

    // MARK: - Timer

    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func stopTimer() {
        AppLog.shared.debug("[Swap] Stop timer")
        refreshDataTimerBag?.cancel()
        refreshDataTimer
            .connect()
            .cancel()
    }

    func startTimer() {
        AppLog.shared.debug("[Swap] Start timer")
        let timeStarted = Date().timeIntervalSince1970
        refreshDataTimerBag = refreshDataTimer
            .autoconnect()
            .sink { [weak self] date in
                // TODO: Update permission remain time to deadline every second

                let timeElapsed = (date.timeIntervalSince1970 - timeStarted).rounded()
                if Int(timeElapsed) % 10 == 0 {
                    AppLog.shared.debug("[Swap] Timer call autoupdate")
                    self?.exchangeManager.refresh(type: .refreshRates)
                }
            }
    }
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(SwappingFeeRowViewModel)
        case warning(DefaultWarningRowViewModel)
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

extension SwappingViewModel {
    private enum Constants {
        static let highPriceImpactWarningLimit: Decimal = 10
    }
}
