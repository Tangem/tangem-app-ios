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

class LegacyMainViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.rateAppService) private var rateAppService: RateAppService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    // MARK: - Published variables

    @Published var error: AlertBinder?
    @Published var showTradeSheet: Bool = false
    @Published var showSelectWalletSheet: Bool = false
    @Published var image: UIImage? = nil
    @Published var hasPendingDerivations: Bool = false
    @Published var isBackupAllowed: Bool = false
    @Published var promotionAvailable: Bool = false
    @Published var promotionRequestInProgress: Bool = false

    @Published var exchangeButtonState: ExchangeButtonState = .single(option: .buy)
    @Published var exchangeActionSheet: ActionSheetBinder?

    @Published var singleWalletContentViewModel: LegacySingleWalletContentViewModel? {
        didSet {
            singleWalletContentViewModel?.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    objectWillChange.send()
                })
                .store(in: &bag)
        }
    }

    @Published var multiWalletContentViewModel: LegacyMultiWalletContentViewModel? {
        didSet {
            multiWalletContentViewModel?.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] in
                    objectWillChange.send()
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

    private let cardImageProvider: CardImageProviding
    private var bag = Set<AnyCancellable>()
    private var isProcessingNewCard = false
    private var imageLoadingSubscription: AnyCancellable?

    private lazy var testnetBuyCryptoService = TestnetBuyCryptoService()

    private unowned let coordinator: LegacyMainRoutable

    public var canSend: Bool {
        singleWalletContentViewModel?.canSend ?? false
    }

    var wallet: Wallet? {
        singleWalletContentViewModel?.singleWalletModel.wallet
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

    var learnAndEarnTitle: String {
        Localization.commonLearnAndEarn
    }

    var learnAndEarnSubtitle: String {
        if let _ = promotionService.promoCode {
            return Localization.mainGetBonusSubtitle
        } else {
            return Localization.mainLearnSubtitle(promotionService.awardAmount ?? 0)
        }
    }

    init(
        cardModel: CardViewModel,
        cardImageProvider: CardImageProviding,
        coordinator: LegacyMainRoutable
    ) {
        self.cardModel = cardModel
        self.cardImageProvider = cardImageProvider
        self.coordinator = coordinator

        bind()
        setupWarnings()
        updateContent()
        updateExchangeButtons()

        if cardModel.canParticipateInPromotion {
            runTask { [weak self] in
                await self?.updatePromotionState()
            }
        }
    }

    deinit {
        AppLog.shared.debug("MainViewModel deinit")
    }

    // MARK: - Functions

    func bind() {
        cardModel.derivationManager?.hasPendingDerivations
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .weakAssign(to: \.hasPendingDerivations, on: self)
            .store(in: &bag)

        AppSettings.shared.$saveUserWallets
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        promotionService.readyForAwardPublisher
            .sink { [weak self] in
                self?.didBecomeReadyForAward()
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
        Analytics.log(.mainScreenOpened)
        updateIsBackupAllowed()
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.noticeScanYourCardTapped)
        cardModel.userTokensManager.deriveIfNeeded(completion: { _ in })
    }

    func extractSellCryptoRequest(from response: String) {
        if let request = exchangeService.extractSellCryptoRequest(from: response) {
            openSendToSell(with: request)
        }
    }

    func learnAndEarn() {
        if promotionRequestInProgress {
            return
        }

        let newClient = (promotionService.promoCode != nil)
        Analytics.logPromotionEvent(.mainNoticeLearnAndEarn, programName: promotionService.currentProgramName, newClient: newClient)

        promotionRequestInProgress = true

        runTask { [weak self] in
            guard let self else { return }

            do {
                try await promotionService.checkIfCanGetAward(userWalletId: cardModel.userWalletId.stringValue)

                if promotionService.promoCode == nil {
                    coordinator.openPromotion(
                        cardPublicKey: cardModel.cardPublicKey.hex,
                        cardId: cardModel.cardId,
                        walletId: cardModel.userWalletId.stringValue
                    )
                } else {
                    try await startPromotionAwardProcess()
                }

                await updatePromotionState()
            } catch {
                handlePromotionError(error)
            }
        }
    }

    func prepareForBackup() {
        if let input = cardModel.backupInput {
            Analytics.log(.noticeBackupYourWalletTapped)
            openOnboarding(with: input)
        }
    }
}

// MARK: - Warnings related

extension LegacyMainViewModel {
    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningView.WarningButton) {
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
            rateAppService.userReactToRateAppWarning(isPositive: true)
        case .dismiss:
            rateAppService.dismissRateAppWarning()
        case .reportProblem:
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
                            self?.cardModel.warningsService.hideWarning(warning)
                        }
                    }
                ))
                return
            }
        }

        cardModel.warningsService.hideWarning(warning)
    }

    private func setupWarnings() {
        cardModel.warningsService.warningsUpdatePublisher
            .sink { [weak self] in
                guard let self else { return }

                AppLog.shared.debug("⚠️ Main view model fetching warnings")
                warnings = cardModel.warningsService.warnings(for: .main)
            }
            .store(in: &bag)

        cardModel.setupWarnings()
    }
}

private extension LegacyMainViewModel {
    // MARK: - Private functions

    private func updateContent() {
        updateIsBackupAllowed()
        loadImage()

        if cardModel.isMultiWallet {
            multiWalletContentViewModel = LegacyMultiWalletContentViewModel(
                walletModelsManager: cardModel.walletModelsManager,
                userTokenListManager: cardModel.userTokenListManager,
                totalBalanceProvider: cardModel.totalBalanceProvider,
                output: self
            )
        } else {
            if let singleWalletModel = cardModel.walletModelsManager.walletModels.first {
                singleWalletContentViewModel = LegacySingleWalletContentViewModel(
                    walletModel: singleWalletModel,
                    walletModelsManager: cardModel.walletModelsManager,
                    totalBalanceProvider: cardModel.totalBalanceProvider,
                    output: self
                )
            }
        }
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

    private func didBecomeReadyForAward() {
        promotionRequestInProgress = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            runTask { [weak self] in
                guard let self else { return }

                do {
                    try await startPromotionAwardProcess()
                    await updatePromotionState()
                } catch {
                    handlePromotionError(error)
                }
            }
        }
    }

    private func handlePromotionError(_ error: Error) {
        AppLog.shared.error(error)

        showAlert(error.alertBinder)

        let fatalPromotionErrorCodes: [TangemAPIError.ErrorCode] = [
            .promotionCodeNotApplied,
            .promotionCodeAlreadyUsed,
            .promotionWalletAlreadyAwarded,
            .promotionCardAlreadyAwarded,
            .promotionProgramNotFound,
            .promotionProgramEnded,
            .promotionCodeNotFound,
        ]

        let promotionAvailable: Bool
        if let apiError = error as? TangemAPIError,
           fatalPromotionErrorCodes.contains(apiError.code) {
            promotionAvailable = false
        } else {
            promotionAvailable = promotionService.promotionAvailable
        }

        didFinishCheckingPromotion(promotionAvailable: promotionAvailable)
    }

    private func startPromotionAwardProcess() async throws {
        let awardedBlockchain = try await promotionService.claimReward(
            userWalletId: cardModel.userWalletId.stringValue,
            userTokensManager: cardModel.userTokensManager
        )

        if let awardedBlockchain {
            let newClient = (promotionService.promoCode != nil)
            Analytics.logPromotionEvent(.mainNoticeSuccessfulClaim, programName: promotionService.currentProgramName, newClient: newClient)

            showAlert(AlertBuilder.makeSuccessAlert(message: Localization.mainPromotionCredited(awardedBlockchain.displayName)))
        }
    }

    private func updatePromotionState() async {
        let isNewCard = (promotionService.promoCode != nil)
        let userWalletId = cardModel.userWalletId.stringValue
        await promotionService.checkPromotion(isNewCard: isNewCard, userWalletId: userWalletId, timeout: nil)

        didFinishCheckingPromotion(promotionAvailable: promotionService.promotionAvailable)
    }

    @MainActor
    private func didFinishCheckingPromotion(promotionAvailable: Bool) {
        self.promotionAvailable = promotionAvailable
        promotionRequestInProgress = false
    }

    @MainActor
    private func showAlert(_ alert: AlertBinder) {
        error = alert
    }
}

extension LegacyMainViewModel {
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

extension LegacyMainViewModel {
    func openSettings() {
        coordinator.openSettings(cardModel: cardModel)
    }

    func openSend(for amountToSend: Amount) {
        guard let blockchainNetwork = cardModel.walletModelsManager.walletModels.first?.blockchainNetwork else { return }

        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: cardModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        guard let blockchainNetwork = cardModel.walletModelsManager.walletModels.first?.blockchainNetwork else { return }

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
        Analytics.log(.buttonBuy)

        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let walletModel = cardModel.walletModelsManager.walletModels.first,
           walletModel.wallet.blockchain == .ethereum(testnet: true),
           let token = walletModel.wallet.amounts.keys.compactMap({ $0.token }).first {
            testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletModel: walletModel, signer: cardModel.signer))
        }

        if let url = buyCryptoURL {
            coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                guard let self = self else { return }

                let code = currencyCode
                Analytics.log(event: .tokenBought, params: [.token: code])

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.cardModel.walletModelsManager.updateAll(silent: true, completion: {})
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

extension LegacyMainViewModel: LegacySingleWalletContentViewModelOutput {
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

extension LegacyMainViewModel: LegacyMultiWalletContentViewModelOutput {
    func openTokensList() {
        var blockchains = cardModel.config.supportedBlockchains
        blockchains.remove(.ducatus)

        let settings = LegacyManageTokensSettings(
            supportedBlockchains: blockchains,
            hdWalletsSupported: cardModel.config.hasFeature(.hdWallets),
            longHashesSupported: cardModel.config.hasFeature(.longHashes),
            derivationStyle: cardModel.config.derivationStyle,
            shouldShowLegacyDerivationAlert: cardModel.shouldShowLegacyDerivationAlert,
            existingCurves: cardModel.card.walletCurves
        )

        coordinator.openLegacyTokensList(
            with: settings,
            userTokensManager: cardModel.userTokensManager
        )
    }

    func openTokenDetails(_ tokenItem: LegacyTokenItemViewModel) {
        coordinator.openTokenDetails(
            cardModel: cardModel,
            blockchainNetwork: tokenItem.blockchainNetwork,
            amountType: tokenItem.amountType
        )
    }
}
