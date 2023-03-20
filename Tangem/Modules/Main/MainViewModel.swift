//
//  MainViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import SwiftUI
import TangemSdk

class MainViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.rateAppService) private var rateAppService: RateAppService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing

    // MARK: - Published variables

    @Published var error: AlertBinder?
    @Published var showTradeSheet: Bool = false
    @Published var showSelectWalletSheet: Bool = false
    @Published var image: UIImage? = nil
    @Published var isLackDerivationWarningViewVisible: Bool = false
    @Published var isBackupAllowed: Bool = false

    @Published var exchangeButtonState: ExchangeButtonState = .single(option: .buy)
    @Published var exchangeActionSheet: ActionSheetBinder?

    @Published var singleWalletContentViewModel: SingleWalletContentViewModel? {
        didSet {
            singleWalletContentViewModel?.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    withAnimation {
                        self.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    @Published var multiWalletContentViewModel: MultiWalletContentViewModel? {
        didSet {
            multiWalletContentViewModel?.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    withAnimation {
                        self.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    @ObservedObject var warnings: WarningsContainer = .init() {
        didSet {
            warnings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    withAnimation {
                        self.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    // MARK: - Private

    @Published var cardModel: CardViewModel {
        didSet {
            cardModel.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    withAnimation {
                        self.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    private var userWalletModel: UserWalletModel
    private let cardImageProvider: CardImageProviding
    private var bag = Set<AnyCancellable>()
    private var isProcessingNewCard = false
    private var imageLoadingSubscription: AnyCancellable?

    private lazy var testnetBuyCryptoService = TestnetBuyCryptoService()

    private unowned let coordinator: MainRoutable

    public var canSend: Bool {
        singleWalletContentViewModel?.canSend ?? false
    }

    var wallet: Wallet? {
        singleWalletContentViewModel?.singleWalletModel?.wallet
    }

    var currencyCode: String {
        wallet?.blockchain.currencySymbol ?? .unknown
    }

    var canBuyCrypto: Bool {
        cardModel.canExchangeCrypto && buyCryptoURL != nil
    }

    var canSellCrypto: Bool {
        cardModel.canExchangeCrypto && sellCryptoURL != nil
    }

    var cardsCountLabel: String? {
        cardModel.cardSetLabel
    }

    var buyCryptoURL: URL? {
        if let wallet {
            let blockchain = wallet.blockchain
            if blockchain.isTestnet {
                return blockchain.testnetFaucetURL
            }

            return exchangeService.getBuyUrl(
                currencySymbol: wallet.blockchain.currencySymbol,
                amountType: .coin,
                blockchain: wallet.blockchain,
                walletAddress: wallet.address
            )
        }
        return nil
    }

    var sellCryptoURL: URL? {
        if let wallet {
            return exchangeService.getSellUrl(
                currencySymbol: wallet.blockchain.currencySymbol,
                amountType: .coin,
                blockchain: wallet.blockchain,
                walletAddress: wallet.address
            )
        }

        return nil
    }

    var buyCryptoCloseUrl: String {
        exchangeService.successCloseUrl.removeLatestSlash()
    }

    var sellCryptoCloseUrl: String {
        exchangeService.sellRequestUrl.removeLatestSlash()
    }

    var isMultiWalletMode: Bool {
        cardModel.isMultiWallet
    }

    var canShowSend: Bool {
        cardModel.canShowSend
    }

    var saveUserWallets: Bool {
        AppSettings.shared.saveUserWallets
    }

    init(
        cardModel: CardViewModel,
        userWalletModel: UserWalletModel,
        cardImageProvider: CardImageProviding,
        coordinator: MainRoutable
    ) {
        self.cardModel = cardModel
        self.userWalletModel = userWalletModel
        self.cardImageProvider = cardImageProvider
        self.coordinator = coordinator

        bind()
        cardModel.setupWarnings()
        updateContent()
        updateExchangeButtons()
    }

    deinit {
        AppLog.shared.debug("MainViewModel deinit")
    }

    // MARK: - Functions

    func bind() {
        warningsService.warningsUpdatePublisher
            .sink { [unowned self] in
                AppLog.shared.debug("⚠️ Main view model fetching warnings")
                self.warnings = self.warningsService.warnings(for: .main)
            }
            .store(in: &bag)

        userWalletModel.subscribeToEntriesWithoutDerivation()
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [unowned self] entries in
                self.updateLackDerivationWarningView(entries: entries)
            }
            .store(in: &bag)

        AppSettings.shared.$saveUserWallets
            .dropFirst()
            .sink { _ in
                self.objectWillChange.send()
            }
            .store(in: &bag)
    }

    func updateExchangeButtons() {
        exchangeButtonState = .init(
            options: ExchangeButtonType.build(
                canBuyCrypto: canBuyCrypto,
                canSellCrypto: canSellCrypto
            )
        )
    }

    func updateIsBackupAllowed() {
        if isBackupAllowed != cardModel.canCreateBackup {
            isBackupAllowed = cardModel.canCreateBackup
        }
    }

    func getDataCollector(for feedbackCase: EmailFeedbackCase) -> EmailDataCollector {
        switch feedbackCase {
        case .negativeFeedback:
            return NegativeFeedbackDataCollector(userWalletEmailData: cardModel.emailData)
        case .scanTroubleshooting:
            return failedCardScanTracker
        }
    }

    func onRefresh(_ done: @escaping () -> Void) {
        Analytics.log(.mainRefreshed)
        if let singleWalletContentViewModel = singleWalletContentViewModel {
            singleWalletContentViewModel.onRefresh {
                withAnimation { done() }
            }
        }

        if let multiWalletContentViewModel = multiWalletContentViewModel {
            multiWalletContentViewModel.onRefresh {
                withAnimation { done() }
            }
        }

        loadImage()
    }

    func onScan() {
        DispatchQueue.main.async {
            Analytics.beginLoggingCardScan(source: .main)
            self.coordinator.close(newScan: true)
        }
    }

    func didTapUserWalletListButton() {
        Analytics.log(.buttonMyWallets)
        coordinator.openUserWalletList()
    }

    func openExchangeActionSheet() {
        Analytics.log(.buttonExchange)

        var buttons: [ActionSheet.Button] = exchangeButtonState.options.map { action in
            .default(Text(action.title)) { [weak self] in
                self?.didTapExchangeButtonAction(type: action)
            }
        }

        buttons.append(.cancel())

        let sheet = ActionSheet(title: Text(""), buttons: buttons)
        exchangeActionSheet = ActionSheetBinder(sheet: sheet)
    }

    func didTapExchangeButtonAction(type: ExchangeButtonType) {
        switch type {
        case .buy:
            openBuyCryptoIfPossible()
        case .sell:
            openSellCrypto()
        case .swap:
            break
        }
    }

    func isAvailable(type: ExchangeButtonType) -> Bool {
        switch type {
        case .buy:
            return canBuyCrypto
        case .sell:
            return canSellCrypto
        case .swap:
            return false
        }
    }

    func sendTapped() {
        guard let wallet else { return }

        Analytics.log(.buttonSend)

        let hasTokenAmounts = !wallet.amounts.values.filter { $0.type.isToken && !$0.isZero }.isEmpty

        if hasTokenAmounts {
            showSelectWalletSheet.toggle()
        } else {
            openSend(for: Amount(with: wallet.amounts[.coin]!, value: 0))
        }
    }

    func onAppear() {
        updateIsBackupAllowed()
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.noticeScanYourCardTapped)
        cardModel.deriveEntriesWithoutDerivation()
    }

    // MARK: - Warning action handler

    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        func registerValidatedSignedHashesCard() {
            AppSettings.shared.validatedSignedHashesCards.append(cardModel.cardId)
        }

        func handleOkGotItButtonAction() {
            switch warning.event {
            case .numberOfSignedHashesIncorrect:
                registerValidatedSignedHashesCard()
            case .systemDeprecationTemporary:
                deprecationService.didDismissSystemDeprecationWarning()
            default:
                return
            }
        }

        // TODO: refactoring
        switch button {
        case .okGotIt:
            handleOkGotItButtonAction()
        case .rateApp:
            Analytics.log(.positiveRateAppFeedback)
            rateAppService.userReactToRateAppWarning(isPositive: true)
        case .dismiss:
            Analytics.log(.dismissRateAppWarning)
            rateAppService.dismissRateAppWarning()
        case .reportProblem:
            Analytics.log(.negativeRateAppFeedback)
            rateAppService.userReactToRateAppWarning(isPositive: false)
            openMail(with: .negativeFeedback)
        case .learnMore:
            if case .multiWalletSignedHashes = warning.event {
                error = AlertBinder(alert: Alert(
                    title: Text(warning.title),
                    message: Text(Localization.alertSignedHashesMessage),
                    primaryButton: .cancel(),
                    secondaryButton: .default(Text(Localization.commonUnderstand)) { [weak self] in
                        withAnimation {
                            registerValidatedSignedHashesCard()
                            self?.warningsService.hideWarning(warning)
                        }
                    }
                ))
                return
            }
        }

        warningsService.hideWarning(warning)
    }

    func extractSellCryptoRequest(from response: String) {
        if let request = exchangeService.extractSellCryptoRequest(from: response) {
            openSendToSell(with: request)
        }
    }

    func prepareForBackup() {
        if let input = cardModel.backupInput {
            Analytics.log(.noticeBackupYourWalletTapped)
            openOnboarding(with: input)
        }
    }

    // MARK: - Private functions

    private func updateContent() {
        updateIsBackupAllowed()
        loadImage()

        if cardModel.isMultiWallet {
            multiWalletContentViewModel = MultiWalletContentViewModel(
                cardModel: cardModel,
                userWalletModel: userWalletModel,
                userTokenListManager: userWalletModel.userTokenListManager,
                output: self
            )
        } else {
            singleWalletContentViewModel = SingleWalletContentViewModel(
                cardModel: cardModel,
                userWalletModel: userWalletModel,
                output: self
            )
        }
    }

    private func setError(_ error: AlertBinder?) {
        if self.error != nil {
            return
        }

        self.error = error
    }

    private func updateLackDerivationWarningView(entries: [StorageEntry]) {
        isLackDerivationWarningViewVisible = !entries.isEmpty
    }

    private func loadImage() {
        imageLoadingSubscription = cardImageProvider
            .loadImage(cardId: cardModel.cardId, cardPublicKey: cardModel.cardPublicKey)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] loaderResult in
                let uiImage = loaderResult.uiImage
                switch loaderResult {
                case .downloaded:
                    withAnimation {
                        self?.image = uiImage
                    }
                case .cached, .embedded:
                    self?.image = uiImage
                }
            })
    }
}

extension MainViewModel {
    enum EmailFeedbackCase: Int, Identifiable {
        case negativeFeedback
        case scanTroubleshooting

        var id: Int { rawValue }

        var emailType: EmailType {
            switch self {
            case .negativeFeedback: return .negativeRateAppFeedback
            case .scanTroubleshooting: return .failedToScanCard
            }
        }
    }
}

// MARK: - Navigation

extension MainViewModel {
    func openSettings() {
        coordinator.openSettings(cardModel: cardModel)
    }

    func openSend(for amountToSend: Amount) {
        guard let blockchainNetwork = cardModel.walletModels.first?.blockchainNetwork else { return }

        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: cardModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        guard let blockchainNetwork = cardModel.walletModels.first?.blockchainNetwork else { return }

        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(
            amountToSend: amount,
            destination: request.targetAddress,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardModel
        )
    }

    func openSellCrypto() {
        Analytics.log(.buttonSell)

        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let url = sellCryptoURL {
            coordinator.openSellCrypto(at: url, sellRequestUrl: sellCryptoCloseUrl) { [weak self] response in
                self?.extractSellCryptoRequest(from: response)
            }
        }
    }

    func openBuyCrypto() {
        Analytics.log(.buttonBuyMainScreen)

        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let walletModel = cardModel.walletModels.first,
           walletModel.wallet.blockchain == .ethereum(testnet: true),
           let token = walletModel.wallet.amounts.keys.compactMap({ $0.token }).first {
            testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletManager: walletModel.walletManager, signer: cardModel.signer))
        }

        if let url = buyCryptoURL {
            coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                guard let self = self else { return }

                let code = self.currencyCode
                Analytics.log(event: .userBoughtCrypto, params: [.currencyCode: code])
                Analytics.log(event: .tokenBought, params: [.token: code])

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.userWalletModel.updateAndReloadWalletModels()
                }
            }
        }
    }

    func openBuyCryptoIfPossible() {
        Analytics.log(.buttonBuy)

        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator.openBankWarning {
                self.openBuyCrypto()
            } declineCallback: {
                self.coordinator.openP2PTutorial()
            }
        } else {
            openBuyCrypto()
        }
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openMail(with emailFeedbackCase: EmailFeedbackCase) {
        let collector = getDataCollector(for: emailFeedbackCase)
        let type = emailFeedbackCase.emailType
        let recipient = cardModel.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator.openMail(with: collector, emailType: type, recipient: recipient)
    }
}

// MARK: - SingleWalletContentViewModelOutput

extension MainViewModel: SingleWalletContentViewModelOutput {
    func openPushTx(for index: Int, walletModel: WalletModel) {
        let tx = walletModel.wallet.pendingOutgoingTransactions[index]
        coordinator.openPushTx(for: tx, blockchainNetwork: walletModel.blockchainNetwork, card: cardModel)
    }

    func openQR(shareAddress: String, address: String, qrNotice: String) {
        coordinator.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }

    func showExplorerURL(url: URL?, walletModel: WalletModel) {
        guard let url = url else { return }

        Analytics.log(.buttonExplore)

        let blockchainName = walletModel.blockchainNetwork.blockchain.displayName
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainName)
    }

    func openCurrencySelection() {
        coordinator.openCurrencySelection(autoDismiss: true)
    }
}

// MARK: - MultiWalletContentViewModelOutput

extension MainViewModel: MultiWalletContentViewModelOutput {
    func openTokensList() {
        coordinator.openTokensList(with: cardModel)
    }

    func openTokenDetails(_ tokenItem: TokenItemViewModel) {
        coordinator.openTokenDetails(
            cardModel: cardModel,
            blockchainNetwork: tokenItem.blockchainNetwork,
            amountType: tokenItem.amountType
        )
    }
}
