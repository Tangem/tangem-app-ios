//
//  CardViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine
import Alamofire
import SwiftUI

class CardViewModel: Identifiable, ObservableObject {
    // MARK: Services

    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var currentSecurityOption: SecurityModeOption = .longTap
    @Published private(set) var accessCodeRecoveryEnabled: Bool

    var signer: TangemSigner { _signer }

    var cardInteractor: CardInteractor {
        .init(tangemSdk: config.makeTangemSdk(), cardId: cardId)
    }

    var cardId: String { cardInfo.card.cardId }

    var card: CardDTO {
        cardInfo.card
    }

    var walletData: DefaultWalletData {
        cardInfo.walletData
    }

    var batchId: String { cardInfo.card.batchId }
    var cardPublicKey: Data { cardInfo.card.cardPublicKey }
    var derivationStyle: DerivationStyle? {
        cardInfo.card.derivationStyle
    }

    var supportsOnlineImage: Bool {
        config.hasFeature(.onlineImage)
    }

    var isMultiWallet: Bool {
        config.hasFeature(.multiCurrency)
    }

    var canDisplayHashesCount: Bool {
        config.hasFeature(.displayHashesCount)
    }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var emailConfig: EmailConfig? {
        config.emailConfig
    }

    var cardsCount: Int {
        config.cardsCount
    }

    var cardIdFormatted: String {
        cardInfo.cardIdFormatted
    }

    var cardIssuer: String {
        cardInfo.card.issuer.name
    }

    var cardSignedHashes: Int {
        cardInfo.card.walletSignedHashes
    }

    var artworkInfo: ArtworkInfo? {
        CardImageProvider().cardArtwork(for: cardInfo.card.cardId)?.artworkInfo
    }

    var name: String {
        cardInfo.name
    }

    var defaultName: String {
        config.cardName
    }

    var canCreateBackup: Bool {
        !config.getFeatureAvailability(.backup).isHidden
    }

    var canSkipBackup: Bool {
        config.canSkipBackup
    }

    var canTwin: Bool {
        config.hasFeature(.twinning)
    }

    var canChangeAccessCodeRecoverySettings: Bool {
        config.hasFeature(.accessCodeRecoverySettings)
    }

    var hasBackupCards: Bool {
        cardInfo.card.backupStatus?.isActive ?? false
    }

    var shouldShowWC: Bool {
        !config.getFeatureAvailability(.walletConnect).isHidden
    }

    var cardDisclaimer: TOU {
        config.tou
    }

    var embeddedEntry: StorageEntry? {
        config.embeddedBlockchain
    }

    var hasTokenSynchronization: Bool {
        config.hasFeature(.tokenSynchronization)
    }

    var canShowSwapping: Bool {
        !config.getFeatureAvailability(.swapping).isHidden
    }

    // Temp for WC. Migrate to userWalletId?
    var secp256k1SeedKey: Data? {
        cardInfo.card.wallets.last(where: { $0.curve == .secp256k1 })?.publicKey
    }

    let userWalletId: UserWalletId

    private let walletListManager: WalletListManager
    let userTokenListManager: UserTokenListManager

    lazy var totalBalanceProvider: TotalBalanceProviding = TotalBalanceProvider(
        userWalletModel: self,
        userWalletAmountType: config.cardAmountType
    )

    private(set) var cardInfo: CardInfo
    private var tangemSdk: TangemSdk?
    private var config: UserWalletConfig
    private var didPerformInitialUpdate = false
    private var reloadAllWalletModelsSubscription: AnyCancellable?

    var availableSecurityOptions: [SecurityModeOption] {
        var options: [SecurityModeOption] = []

        if canSetLongTap || currentSecurityOption == .longTap {
            options.append(.longTap)
        }

        if config.hasFeature(.accessCode) || currentSecurityOption == .accessCode {
            options.append(.accessCode)
        }

        if config.hasFeature(.passcode) || currentSecurityOption == .passCode {
            options.append(.passCode)
        }

        return options
    }

    var hdWalletsSupported: Bool {
        config.hasFeature(.hdWallets)
    }

    var walletModels: [WalletModel] {
        getWalletModels()
    }

    var wallets: [Wallet] {
        walletModels.map { $0.wallet }
    }

    var canSetLongTap: Bool {
        config.hasFeature(.longTap)
    }

    var longHashesSupported: Bool {
        config.hasFeature(.longHashes)
    }

    var canSend: Bool {
        config.hasFeature(.send)
    }

    var cardAmountType: Amount.AmountType? {
        config.cardAmountType
    }

    var hasWallet: Bool {
        !walletModels.isEmpty
    }

    var cardSetLabel: String? {
        config.cardSetLabel
    }

    var canShowAddress: Bool {
        config.hasFeature(.receive)
    }

    var canShowTransactionHistory: Bool {
        config.hasFeature(.transactionHistory)
    }

    var canShowSend: Bool {
        config.hasFeature(.withdrawal)
    }

    var canParticipateInReferralProgram: Bool {
        // TODO: refactor to a single function that any other entity can use to request feature availability
        !config.getFeatureAvailability(.referralProgram).isHidden
    }

    var supportedBlockchains: Set<Blockchain> {
        config.supportedBlockchains
    }

    var backupInput: OnboardingInput? {
        let factory = OnboardingInputFactory(
            cardInfo: cardInfo,
            cardModel: self,
            sdkFactory: config,
            onboardingStepsBuilderFactory: config
        )

        return factory.makeBackupInput()
    }

    var twinInput: OnboardingInput? {
        guard let twinData = cardInfo.walletData.twinData else {
            return nil
        }

        let factory = TwinInputFactory(
            cardInput: .cardModel(self),
            userWalletToDelete: userWallet,
            twinData: twinData,
            sdkFactory: config
        )
        return factory.makeTwinInput()
    }

    var resetToFactoryAvailability: UserWalletFeature.Availability {
        config.getFeatureAvailability(.resetToFactory)
    }

    var shouldShowLegacyDerivationAlert: Bool {
        config.warningEvents.contains(where: { $0 == .legacyDerivation })
    }

    var canExchangeCrypto: Bool { !config.getFeatureAvailability(.exchange).isHidden }

    var userWallet: UserWallet {
        UserWalletFactory().userWallet(from: cardInfo, config: config, userWalletId: userWalletId)
    }

    var productType: Analytics.ProductType {
        config.productType
    }

    private var isActive: Bool {
        if let selectedUserWalletId = userWalletRepository.selectedUserWalletId {
            return selectedUserWalletId == userWalletId.value
        } else {
            return true
        }
    }

    private var searchBlockchainsCancellable: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var signSubscription: AnyCancellable?
    private var derivationManager: DerivationManager?

    private var _signer: TangemSigner {
        didSet {
            bindSigner()
        }
    }

    convenience init?(userWallet: UserWallet) {
        let cardInfo = userWallet.cardInfo()
        self.init(cardInfo: cardInfo)
    }

    init?(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else {
            return nil
        }

        self.cardInfo = cardInfo
        self.config = config
        userWalletId = UserWalletId(with: userWalletIdSeed)
        userTokenListManager = CommonUserTokenListManager(
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization),
            userWalletId: userWalletId.value
        )

        walletListManager = CommonWalletListManager(
            config: config,
            userTokenListManager: userTokenListManager
        )

        _signer = config.tangemSigner
        accessCodeRecoveryEnabled = cardInfo.card.userSettings.isUserCodeRecoveryAllowed
        updateCurrentSecurityOption()
        appendPersistentBlockchains()
        bind()
    }

    func setupWarnings() {
        warningsService.setupWarnings(
            for: config,
            card: cardInfo.card,
            validator: walletModels.first?.walletManager as? SignatureCountValidator
        )
    }

    func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        append(entries: persistentBlockchains)
    }

    func appendDefaultBlockchains() {
        append(entries: config.defaultBlockchains)
    }

    func deriveEntriesWithoutDerivation() {
        derive(entries: getEntriesWithoutDerivation()) { [weak self] result in
            switch result {
            case .success:
                self?.updateAndReloadWalletModels()
            case .failure:
                AppLog.shared.debug("Derivation error")
            }
        }
    }

    // MARK: - Security

    func changeSecurityOption(_ option: SecurityModeOption, completion: @escaping (Result<Void, Error>) -> Void) {
        let tangemSdk = makeTangemSdk()
        self.tangemSdk = tangemSdk
        switch option {
        case .accessCode:
            tangemSdk.startSession(
                with: SetUserCodeCommand(accessCode: nil),
                cardId: cardId,
                initialMessage: Message(header: nil, body: Localization.initialMessageChangeAccessCodeBody)
            ) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.onSecurityOptionChanged(isAccessCodeSet: true, isPasscodeSet: false)
                    Analytics.log(.userCodeChanged)
                    completion(.success(()))
                case .failure(let error):
                    AppLog.shared.error(
                        error,
                        params: [
                            .newSecOption: .accessCode,
                            .action: .changeSecOptions,
                        ]
                    )
                    completion(.failure(error))
                }
            }
        case .longTap:
            tangemSdk.startSession(
                with: SetUserCodeCommand.resetUserCodes,
                cardId: cardId
            ) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.onSecurityOptionChanged(isAccessCodeSet: false, isPasscodeSet: false)
                    completion(.success(()))
                case .failure(let error):
                    AppLog.shared.error(
                        error,
                        params: [
                            .newSecOption: .longTap,
                            .action: .changeSecOptions,
                        ]
                    )
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.startSession(
                with: SetUserCodeCommand(passcode: nil),
                cardId: cardId,
                initialMessage: Message(header: nil, body: Localization.initialMessageChangePasscodeBody)
            ) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.onSecurityOptionChanged(isAccessCodeSet: false, isPasscodeSet: true)
                    completion(.success(()))
                case .failure(let error):
                    AppLog.shared.error(
                        error,
                        params: [
                            .newSecOption: .passcode,
                            .action: .changeSecOptions,
                        ]
                    )
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Wallet

    func getBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork {
        if let derivationPath = derivationPath {
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        if let derivationStyle = cardInfo.card.derivationStyle {
            let derivationPath = blockchain.derivationPath(for: derivationStyle)
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        return BlockchainNetwork(blockchain, derivationPath: nil)
    }

    // MARK: - Update

    func onSecurityOptionChanged(isAccessCodeSet: Bool, isPasscodeSet: Bool) {
        cardInfo.card.isAccessCodeSet = isAccessCodeSet
        cardInfo.card.isPasscodeSet = isPasscodeSet
        onUpdate()
    }

    func onSigned(_ card: Card) {
        for updatedWallet in card.wallets {
            cardInfo.card.wallets[updatedWallet.publicKey]?.totalSignedHashes = updatedWallet.totalSignedHashes
            cardInfo.card.wallets[updatedWallet.publicKey]?.remainingSignatures = updatedWallet.remainingSignatures
        }

        onUpdate()
    }

    func onDerived(_ response: DerivationResult) {
        for updatedWallet in response {
            for derivedKey in updatedWallet.value.keys {
                cardInfo.card.wallets[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
            }
        }

        onUpdate()
    }

    func onBackupCreated(_ card: Card) {
        for updatedWallet in card.wallets {
            cardInfo.card.wallets[updatedWallet.publicKey]?.hasBackup = updatedWallet.hasBackup
        }

        cardInfo.card.settings = CardDTO.Settings(settings: card.settings)
        cardInfo.card.isAccessCodeSet = card.isAccessCodeSet
        cardInfo.card.backupStatus = card.backupStatus
        onUpdate()
    }

    private func onUpdate() {
        AppLog.shared.debug("🔄 Updating CardViewModel with new Card")
        config = UserWalletConfigFactory(cardInfo).makeConfig()
        walletListManager.update(config: config)
        _signer = config.tangemSigner
        updateModel()
        userWalletRepository.save(userWallet)
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        config.getFeatureAvailability(feature).disabledLocalizedReason
    }

    private func updateModel() {
        AppLog.shared.debug("🔄 Updating Card view model")
        updateCurrentSecurityOption()

        setupWarnings()
    }

    private func searchBlockchains() {
        guard config.hasFeature(.tokensSearch) else { return }

        searchBlockchainsCancellable = nil

        let currentBlockhains = wallets.map { $0.blockchain }
        let unused: [StorageEntry] = config.supportedBlockchains
            .subtracting(currentBlockhains)
            .map { StorageEntry(blockchainNetwork: .init($0, derivationPath: nil), tokens: []) }

        let models = unused.compactMap {
            try? config.makeWalletModel(for: $0)
        }

        if models.isEmpty {
            return
        }

        searchBlockchainsCancellable = Publishers.MergeMany(
            models.map { $0.update(silent: false) }
        )
        .collect()
        .receiveCompletion { [weak self] _ in
            guard let self = self else { return }

            let notEmptyWallets = models.filter { !$0.wallet.isEmpty }
            if !notEmptyWallets.isEmpty {
                let entries = notEmptyWallets.map {
                    StorageEntry(blockchainNetwork: $0.blockchainNetwork, tokens: [])
                }

                // TODO: Check it
                self.add(entries: entries) { _ in }
            }
        }
    }

    private func searchTokens() {
        guard config.hasFeature(.tokensSearch),
              !AppSettings.shared.searchedCards.contains(cardId) else {
            return
        }

        guard let ethBlockchain = config.supportedBlockchains.first(where: {
            if case .ethereum = $0 {
                return true
            }

            return false
        }) else {
            return
        }

        var shouldAddWalletManager = false
        let network = getBlockchainNetwork(for: ethBlockchain, derivationPath: nil)
        var ethWalletModel = walletModels.first(where: { $0.blockchainNetwork == network })

        if ethWalletModel == nil {
            shouldAddWalletManager = true
            let entry = StorageEntry(blockchainNetwork: network, tokens: [])
            ethWalletModel = try? config.makeWalletModel(for: entry)
        }

        guard let ethWalletModel = ethWalletModel,
              let tokenFinder = ethWalletModel.walletManager as? TokenFinder else {
            AppSettings.shared.searchedCards.append(cardId)
            searchBlockchains()
            return
        }

        tokenFinder.findErc20Tokens(knownTokens: []) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let tokensAdded):
                if tokensAdded, shouldAddWalletManager {
                    let tokens = ethWalletModel.walletManager.cardTokens
                    let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
                    // TODO: Check it
                    self.add(entries: [entry]) { _ in }
                }
            case .failure(let error):
                AppLog.shared.error(error)
            }

            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
        }
    }

    private func updateCurrentSecurityOption() {
        if cardInfo.card.isAccessCodeSet {
            currentSecurityOption = .accessCode
        } else if cardInfo.card.isPasscodeSet ?? false {
            currentSecurityOption = .passCode
        } else {
            currentSecurityOption = .longTap
        }
    }

    private func bind() {
        bindSigner()
    }

    private func bindSigner() {
        signSubscription = _signer.signPublisher
            .sink { [weak self] card in // TODO: TBD remaining signatures feature
                self?.onSigned(card)
            }
    }
}

// MARK: - Proxy for User Wallet Model

extension CardViewModel {
    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        return subscribeToWalletModels()
    }

    func add(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        derive(entries: entries) { [weak self] result in
            switch result {
            case .success:
                self?.append(entries: entries)
                self?.updateAndReloadWalletModels()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func update(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        derive(entries: entries) { [weak self] result in
            switch result {
            case .success:
                self?.update(entries: entries)
                self?.updateAndReloadWalletModels()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func derive(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        let derivationManager = DerivationManager(config: config, cardInfo: cardInfo)
        self.derivationManager = derivationManager
        let alreadySaved = getSavedEntries()
        derivationManager.deriveIfNeeded(entries: alreadySaved + entries, completion: { [weak self] result in
            switch result {
            case .success(let response):
                if let response {
                    self?.onDerived(response)
                }

                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self?.derivationManager = nil
        })
    }
}

extension CardViewModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}

extension CardViewModel: WalletConnectUserWalletInfoProvider {}

// MARK: Access code recovery settings provider

extension CardViewModel: AccessCodeRecoverySettingsProvider {
    func setAccessCodeRecovery(to enabled: Bool, _ completionHandler: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let tangemSdk = makeTangemSdk()
        self.tangemSdk = tangemSdk

        tangemSdk.setUserCodeRecoveryAllowed(enabled, cardId: cardId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.cardInfo.card.userSettings.isUserCodeRecoveryAllowed = enabled
                self.accessCodeRecoveryEnabled = enabled
                completionHandler(.success(()))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// TODO: Refactor
extension CardViewModel: TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk {
        config.makeTangemSdk()
    }
}

// MARK: - UserWalletModel

extension CardViewModel: UserWalletModel {
    func getSavedEntries() -> [StorageEntry] {
        userTokenListManager.getEntriesFromRepository()
    }

    func getWalletModels() -> [WalletModel] {
        walletListManager.getWalletModels()
    }

    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeToWalletModels()
    }

    func getEntriesWithoutDerivation() -> [StorageEntry] {
        walletListManager.getEntriesWithoutDerivation()
    }

    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> {
        walletListManager.subscribeToEntriesWithoutDerivation()
    }

    func initialUpdate() {
        guard !didPerformInitialUpdate else {
            AppLog.shared.debug("Initial update has been performed")
            return
        }

        /// It's used to check if the storage needs to be updated when the user adds a new wallet to saved wallets.
        if config.hasFeature(.tokenSynchronization),
           !userTokenListManager.didPerformInitialLoading {
            didPerformInitialUpdate = true

            userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
                self?.updateAndReloadWalletModels()
            }
        } else {
            updateAndReloadWalletModels()
        }
    }

    func updateWalletName(_ name: String) {
        cardInfo.name = name
    }

    func updateWalletModels() {
        // Update walletModel list for current storage state
        walletListManager.updateWalletModels()
    }

    func updateAndReloadWalletModels(silent: Bool, completion: @escaping () -> Void) {
        updateWalletModels()

        reloadAllWalletModelsSubscription = walletListManager
            .reloadWalletModels(silent: silent)
            .receive(on: RunLoop.main)
            .receiveCompletion { _ in
                completion()
            }
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func update(entries: [StorageEntry]) {
        userTokenListManager.update(.rewrite(entries))
    }

    func append(entries: [StorageEntry]) {
        userTokenListManager.update(.append(entries))
    }

    func remove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) {
        guard walletListManager.canRemove(amountType: amountType, blockchainNetwork: blockchainNetwork) else {
            assertionFailure("\(blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch amountType {
        case .coin:
            removeBlockchain(blockchainNetwork)
        case .token(let token):
            removeToken(token, in: blockchainNetwork)
        case .reserve:
            break
        }
    }
}

// MARK: - Wallet models Operations

private extension CardViewModel {
    func removeBlockchain(_ network: BlockchainNetwork) {
        userTokenListManager.update(.removeBlockchain(network))
        walletListManager.updateWalletModels()
    }

    func removeToken(_ token: Token, in network: BlockchainNetwork) {
        userTokenListManager.update(.removeToken(token, in: network))
        walletListManager.removeToken(token, blockchainNetwork: network)
        walletListManager.updateWalletModels()
    }
}
