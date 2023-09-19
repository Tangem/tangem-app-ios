//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError

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

        if isShowingDisclaimer {
            feeOptionsViewModels.forEach {
                viewModels.append(.feePolicy($0))
            }

            if let feeWarningRowViewModel = feeWarningRowViewModel {
                viewModels.append(.warning(feeWarningRowViewModel))
            }

            if let feeInfoRowViewModel = feeInfoRowViewModel {
                viewModels.append(.warning(feeInfoRowViewModel))
            }
        } else if let feeWarningRowViewModel = feeWarningRowViewModel {
            viewModels.append(.warning(feeWarningRowViewModel))
        }

        return viewModels
    }

    @Published private var swappingFeeRowViewModel: SwappingFeeRowViewModel?
    @Published private var feeWarningRowViewModel: DefaultWarningRowViewModel?
    @Published private var feeOptionsViewModels: [SelectableSwappingFeeRowViewModel] = []
    @Published private var feeInfoRowViewModel: DefaultWarningRowViewModel?
    @Published private var isShowingDisclaimer: Bool = false

    // MARK: - Dependencies

    private let initialSourceCurrency: Currency
    private let swappingInteractor: SwappingInteractor
    private let swappingDestinationService: SwappingDestinationServicing
    private let tokenIconURLBuilder: TokenIconURLBuilding
    private let transactionSender: SwappingTransactionSender
    private let fiatRatesProvider: FiatRatesProviding
    private let swappingFeeFormatter: SwappingFeeFormatter
    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private lazy var refreshDataTimer = Timer.publish(every: 10, on: .main, in: .common)
    private var refreshDataTimerBag: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        initialSourceCurrency: Currency,
        swappingInteractor: SwappingInteractor,
        swappingDestinationService: SwappingDestinationServicing,
        tokenIconURLBuilder: TokenIconURLBuilding,
        transactionSender: SwappingTransactionSender,
        fiatRatesProvider: FiatRatesProviding,
        swappingFeeFormatter: SwappingFeeFormatter,
        coordinator: SwappingRoutable
    ) {
        self.initialSourceCurrency = initialSourceCurrency
        self.swappingInteractor = swappingInteractor
        self.swappingDestinationService = swappingDestinationService
        self.tokenIconURLBuilder = tokenIconURLBuilder
        self.transactionSender = transactionSender
        self.fiatRatesProvider = fiatRatesProvider
        self.swappingFeeFormatter = swappingFeeFormatter
        self.coordinator = coordinator

        Analytics.log(event: .swapScreenOpenedSwap, params: [.token: initialSourceCurrency.symbol])
        setupView()
        bind()
        loadDestinationIfNeeded()
    }

    func userDidTapMaxAmount() {
        let sourceBalance = swappingInteractor.getSwappingItems().sourceBalance
        sendDecimalValue = .external(sourceBalance)
        updateSendFiatValue(amount: sourceBalance)
        swappingInteractor.update(amount: sourceBalance)
    }

    func userDidRequestChangeDestination(to currency: Currency) {
        var items = swappingInteractor.getSwappingItems()

        if items.source == initialSourceCurrency {
            items.destination = currency
        } else if items.destination == initialSourceCurrency {
            items.source = currency
        }

        runTask(in: self) { root in
            await root.update(swappingItems: items, shouldRefresh: true)
        }
    }

    func userDidTapSwapSwappingItemsButton() {
        Analytics.log(.swapButtonSwipe)
        var items = swappingInteractor.getSwappingItems()

        guard let destination = items.destination else {
            return
        }

        let source = items.source

        items.source = destination
        items.destination = source

        runTask(in: self) { root in
            await root.update(swappingItems: items, shouldRefresh: false)
        }

        // If we have amount then we should round and update it with new decimalCount
        guard let amount = sendDecimalValue?.value else {
            return
        }

        let roundedAmount = amount.rounded(scale: items.source.decimalCount, roundingMode: .down)
        sendDecimalValue = .external(roundedAmount)
        updateSendFiatValue(amount: roundedAmount)
        swappingInteractor.update(amount: roundedAmount)
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
            openApproveView()
        case .insufficientFunds:
            assertionFailure("Button should be disabled")
        }
    }

    func didCloseApproveSheet() {
        restartTimer()
    }

    func didTapWaringRefresh() {
        swappingInteractor.refresh(type: .full)
    }
}

// MARK: - Navigation

private extension SwappingViewModel {
    func openTokenListView() {
        coordinator.presentSwappingTokenList(sourceCurrency: initialSourceCurrency)
    }

    func openSuccessView(transactionData: SwappingTransactionData, transactionID: String) {
        let sourceAmount = transactionData.sourceCurrency.convertFromWEI(value: transactionData.sourceAmount)
        let destinationAmount = transactionData.destinationCurrency.convertFromWEI(value: transactionData.destinationAmount)

        let source = CurrencyAmount(
            value: sourceAmount,
            currency: transactionData.sourceCurrency
        )

        let result = CurrencyAmount(
            value: destinationAmount,
            currency: transactionData.destinationCurrency
        )

        let inputModel = SwappingSuccessInputModel(
            sourceCurrencyAmount: source,
            resultCurrencyAmount: result,
            transactionID: transactionID
        )

        coordinator.presentSuccessView(inputModel: inputModel)
    }

    func openApproveView() {
        let state = swappingInteractor.getAvailabilityState()

        guard case .available(let model) = state, model.restrictions.isPermissionRequired else {
            return
        }

        stopTimer()
        coordinator.presentApproveView()
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

    func updateView(swappingItems: SwappingItems) {
        updateSendView(swappingItems: swappingItems)
        updateReceiveView(swappingItems: swappingItems)
    }

    func updateSendView(swappingItems: SwappingItems) {
        let source = swappingItems.source

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: .loaded(swappingItems.sourceBalance),
            fiatValue: .loading,
            maximumFractionDigits: source.decimalCount,
            canChangeCurrency: source != initialSourceCurrency,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: source)
        )

        updateSendFiatValue(amount: sendDecimalValue?.value)
    }

    func updateSendFiatValue(amount: Decimal?) {
        guard let amount = amount else {
            sendCurrencyViewModel?.update(fiatValue: .loaded(0))
            return
        }

        let source = swappingInteractor.getSwappingItems().source
        if !fiatRatesProvider.hasRates(for: source) {
            sendCurrencyViewModel?.update(fiatValue: .loading)
        }

        runTask(in: self) { root in
            let fiatValue = try await root.fiatRatesProvider.getFiat(for: source, amount: amount)

            try Task.checkCancellation()

            await runOnMain {
                root.sendCurrencyViewModel?.update(fiatValue: .loaded(fiatValue))
            }
        }
    }

    func updateReceiveView(swappingItems: SwappingItems) {
        let destination = swappingItems.destination

        let cryptoAmountState: ReceiveCurrencyViewModel.State
        let fiatAmountState: ReceiveCurrencyViewModel.State

        switch swappingInteractor.getAvailabilityState() {
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
        case .available(let model):
            cryptoAmountState = .loaded(model.destinationAmount)
            fiatAmountState = .loading
            updateReceiveCurrencyValue(value: model.destinationAmount)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            balance: swappingItems.destinationBalance,
            canChangeCurrency: destination != initialSourceCurrency,
            cryptoAmountState: cryptoAmountState,
            fiatAmountState: fiatAmountState,
            tokenIcon: mapToSwappingTokenIconViewModel(currency: destination)
        )
    }

    func updateState(state: SwappingAvailabilityState) {
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

        case .available(let model):
            refreshWarningRowViewModel = nil
            swapButtonIsLoading = false

            restartTimer()
            updateReceiveCurrencyValue(value: model.destinationAmount)
            updateRequiredPermission(isPermissionRequired: model.restrictions.isPermissionRequired)

            let policy = swappingInteractor.getSwappingGasPricePolicy()
            updateEnoughAmountForFee(isEnoughAmountForFee: model.isEnoughAmountForFee(for: policy))

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

        guard let destination = swappingInteractor.getSwappingItems().destination else { return }

        // If rates will be loaded
        if !fiatRatesProvider.hasRates(for: destination) {
            receiveCurrencyViewModel?.update(fiatAmountState: .loading)
        }

        runTask(in: self) { root in
            let fiatValue = try await root.fiatRatesProvider.getFiat(for: destination, amount: value)

            try Task.checkCancellation()

            await runOnMain {
                root.receiveCurrencyViewModel?.update(fiatAmountState: .loaded(fiatValue))
            }

            try Task.checkCancellation()

            try await root.checkForHighPriceImpact(destinationFiatAmount: fiatValue)
        }
    }

    func updateRequiredPermission(isPermissionRequired: Bool) {
        if isPermissionRequired {
            permissionInfoRowViewModel = DefaultWarningRowViewModel(
                title: Localization.swappingGivePermission,
                subtitle: Localization.swappingPermissionSubheader(swappingInteractor.getSwappingItems().source.symbol),
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
            let sourceBlockchain = swappingInteractor.getSwappingItems().source.blockchain
            feeWarningRowViewModel = DefaultWarningRowViewModel(
                subtitle: Localization.swappingNotEnoughFundsForFee(sourceBlockchain.symbol, sourceBlockchain.symbol),
                leftView: .icon(Assets.attention)
            )
        }
    }

    func updateFeeValue(state: SwappingAvailabilityState) {
        feeOptionsViewModels.removeAll()

        switch state {
        case .idle, .requiredRefresh, .preview:
            swappingFeeRowViewModel?.update(state: .idle)
        case .loading(let type):
            if type == .full {
                swappingFeeRowViewModel?.update(state: .loading)
            }
        case .available(let model):
            updateFeeRowViewModel(transactionData: model.transactionData)
            updateFeeOptionsViewModels(data: model.transactionData, options: model.gasOptions)
        }
    }

    func updateMainButton(state: SwappingAvailabilityState) {
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
            mainButtonIsEnabled = preview.isEnoughAmountForSwapping && !preview.hasPendingTransaction

            if !preview.isEnoughAmountForSwapping {
                mainButtonState = .insufficientFunds
            } else if preview.hasPendingTransaction {
                mainButtonState = .swap
            } else if preview.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }

        case .available(let model):
            let policy = swappingInteractor.getSwappingGasPricePolicy()
            let isEnoughAmountForSwapping = model.isEnoughAmountForSwapping(for: policy)
            let isEnoughAmountForFee = model.isEnoughAmountForFee(for: policy)

            mainButtonIsEnabled = isEnoughAmountForSwapping && isEnoughAmountForFee

            if !isEnoughAmountForSwapping {
                mainButtonState = .insufficientFunds
            } else if model.restrictions.isPermissionRequired {
                mainButtonState = .givePermission
            } else {
                mainButtonState = .swap
            }
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

    func checkForHighPriceImpact(destinationFiatAmount: Decimal) async throws {
        guard let sendDecimalValue = sendDecimalValue?.value else {
            // Current send decimal value was changed during old update. We can ignore this check
            return
        }

        if sendDecimalValue.isZero {
            // No need to calculate price impact with zero input
            await runOnMain {
                highPriceImpactWarningRowViewModel = nil
            }
            return
        }

        let sourceFiatAmount = try await fiatRatesProvider.getFiat(
            for: swappingInteractor.getSwappingItems().source,
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
        }
    }

    func setupView() {
        updateState(state: .idle)
        updateView(swappingItems: swappingInteractor.getSwappingItems())
        swappingFeeRowViewModel = SwappingFeeRowViewModel(
            state: .idle,
            isShowingDisclaimer: .init(
                get: { [weak self] in self?.isShowingDisclaimer ?? false },
                set: { [weak self] isOpen in
                    UIApplication.shared.endEditing()
                    self?.isShowingDisclaimer = isOpen
                }
            )
        )

        feeInfoRowViewModel = makeDefaultWarningRowViewModel()
    }

    func makeDefaultWarningRowViewModel() -> DefaultWarningRowViewModel {
        let percentFee = swappingInteractor.getReferrerAccountFee() ?? 0
        let formattedFee = "\(percentFee.groupedFormatted())%"
        return DefaultWarningRowViewModel(
            subtitle: Localization.swappingTangemFeeDisclaimer(formattedFee),
            leftView: .icon(Assets.heartMini)
        )
    }

    func updateFeeRowViewModel(transactionData: SwappingTransactionData) {
        runTask(in: self) { root in
            let fiatFee = try await root.fiatRatesProvider.getFiat(
                for: transactionData.sourceBlockchain,
                amount: transactionData.fee
            )

            try Task.checkCancellation()
            let currencyCode = await AppSettings.shared.selectedCurrencyCode

            await runOnMain {
                root.swappingFeeRowViewModel?.update(
                    state: .policy(
                        title: transactionData.gas.policy.title,
                        fiat: fiatFee.currencyFormatted(code: currencyCode)
                    )
                )
            }
        }
    }

    func updateFeeOptionsViewModels(data: SwappingTransactionData, options: [EthereumGasDataModel]) {
        feeOptionsViewModels = options.map { gasModel in
            let subtitle = try? swappingFeeFormatter.format(
                fee: gasModel.fee,
                blockchain: gasModel.blockchain
            )

            return SelectableSwappingFeeRowViewModel(
                title: gasModel.policy.title,
                subtitle: subtitle ?? Localization.commonNoData,
                isSelected: .init(
                    get: { data.gas.policy == gasModel.policy },
                    set: { [weak self] isSelected in
                        if isSelected {
                            self?.swappingInteractor.update(gasPricePolicy: gasModel.policy)
                        }
                    }
                )
            )
        }
    }

    func bind() {
        $sendDecimalValue
            .removeDuplicates { $0?.value == $1?.value }
            // We skip the first nil value from the text field
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
            .filter { $0?.isInternal ?? true }
            .handleEvents(receiveOutput: { [weak self] amount in
                self?.swappingInteractor.cancelRefresh()
                self?.updateSendFiatValue(amount: amount?.value)
                self?.stopTimer()
            })
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.resetViews()
                self?.swappingInteractor.update(amount: amount?.value)

                if let amount, amount.value > 0 {
                    self?.startTimer()
                }
            }
            .store(in: &bag)

        swappingInteractor.state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateState(state: state)
            }
            .store(in: &bag)
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
}

// MARK: - Methods

private extension SwappingViewModel {
    func update(swappingItems: SwappingItems, shouldRefresh: Bool) async {
        let updatedItems = await swappingInteractor.update(swappingItems: swappingItems)

        await runOnMain {
            updateView(swappingItems: updatedItems)
        }

        if shouldRefresh {
            swappingInteractor.refresh(type: .full)
        }
    }

    func loadDestinationIfNeeded() {
        guard swappingInteractor.getSwappingItems().destination == nil else {
            AppLog.shared.debug("Swapping item destination has already set")
            return
        }

        runTask(in: self) { root in
            var items = root.swappingInteractor.getSwappingItems()

            do {
                items.destination = try await root.swappingDestinationService.getDestination(source: items.source)
                await root.update(swappingItems: items, shouldRefresh: true)

            } catch {
                AppLog.shared.debug("Destination load handle error")
                AppLog.shared.error(error)
                items.destination = nil
            }
        }
    }

    func swapItems() {
        let state = swappingInteractor.getAvailabilityState()
        guard case .available(let model) = state else {
            return
        }

        let transactionData = model.transactionData

        stopTimer()
        Analytics.log(
            event: .swapButtonSwap,
            params: [
                .sendToken: transactionData.sourceCurrency.symbol,
                .receiveToken: transactionData.destinationCurrency.symbol,
            ]
        )

        runTask(in: self) { root in
            do {
                let sendResult = try await root.transactionSender.sendTransaction(transactionData)

                try Task.checkCancellation()

                root.swappingInteractor.didSendSwapTransaction(swappingTxData: transactionData)

                await runOnMain { [weak root] in
                    root?.openSuccessView(transactionData: transactionData, transactionID: sendResult.hash)
                }
            } catch TangemSdkError.userCancelled {
                root.restartTimer()
            } catch {
                await runOnMain { [weak root] in
                    root?.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }

    func processingError(error: Error) {
        AppLog.shared.debug("DefaultSwappingManager catch error: ")
        AppLog.shared.error(error)

        switch error {
        case let error as SwappingManagerError:
            switch error {
            case .walletAddressNotFound, .destinationNotFound, .amountNotFound, .gasModelNotFound:
                updateRefreshWarningRowViewModel(message: error.localizedDescription)
            }
        case let error as SwappingProviderError:
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
}

// MARK: - Timer

private extension SwappingViewModel {
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
        refreshDataTimerBag = refreshDataTimer
            .autoconnect()
            .sink { [weak self] date in
                AppLog.shared.debug("[Swap] Timer call autoupdate")
                self?.swappingInteractor.refresh(type: .refreshRates)
            }
    }
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(SwappingFeeRowViewModel)
        case warning(DefaultWarningRowViewModel)
        case feePolicy(SelectableSwappingFeeRowViewModel)
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

extension SwappingGasPricePolicy {
    var title: String {
        switch self {
        case .normal:
            return Localization.sendFeePickerNormal
        case .priority:
            return Localization.sendFeePickerPriority
        }
    }
}
