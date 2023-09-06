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

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModelsManager: WalletModelsManager

    lazy var userTokensManager: UserTokensManager = CommonUserTokensManager(
        userTokenListManager: userTokenListManager,
        walletModelsManager: walletModelsManager,
        derivationStyle: config.derivationStyle,
        derivationManager: derivationManager,
        cardDerivableProvider: self
    )

    let userTokenListManager: UserTokenListManager

    private let keysRepository: KeysRepository
    private let walletManagersRepository: WalletManagersRepository

    lazy var derivationManager: DerivationManager? = {
        guard config.hasFeature(.hdWallets) else {
            return nil
        }

        let commonDerivationManager = CommonDerivationManager(
            keysRepository: keysRepository,
            userTokenListManager: userTokenListManager
        )

        commonDerivationManager.delegate = self
        return commonDerivationManager
    }()

    let warningsService = WarningsService()

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

    var supportsOnlineImage: Bool {
        config.hasFeature(.onlineImage)
    }

    var isMultiWallet: Bool {
        config.hasFeature(.multiCurrency)
    }

    var canDisplayHashesCount: Bool {
        config.hasFeature(.displayHashesCount)
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

    var cardDisclaimer: TOU {
        config.tou
    }

    var embeddedEntry: StorageEntry? {
        config.embeddedBlockchain
    }

    var canShowSwapping: Bool {
        !config.getFeatureAvailability(.swapping).isHidden
    }

    // Temp for WC. Migrate to userWalletId?
    var secp256k1SeedKey: Data? {
        cardInfo.card.wallets.last(where: { $0.curve == .secp256k1 })?.publicKey
    }

    let userWalletId: UserWalletId

    lazy var totalBalanceProvider: TotalBalanceProviding = TotalBalanceProvider(
        walletModelsManager: walletModelsManager,
        derivationManager: derivationManager
    )

    private(set) var cardInfo: CardInfo
    private var tangemSdk: TangemSdk?
    var config: UserWalletConfig
    private var didPerformInitialUpdate = false

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

    var canSetLongTap: Bool {
        config.hasFeature(.longTap)
    }

    var longHashesSupported: Bool {
        config.hasFeature(.longHashes)
    }

    var cardSetLabel: String? {
        config.cardSetLabel
    }

    var canShowSend: Bool {
        config.hasFeature(.withdrawal)
    }

    var canParticipateInPromotion: Bool {
        config.hasFeature(.promotion)
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

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>
    private var bag = Set<AnyCancellable>()
    private var signSubscription: AnyCancellable?

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

        guard let userWalletIdSeed = config.userWalletIdSeed,
              let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        self.cardInfo = cardInfo
        self.config = config
        keysRepository = CommonKeysRepository(with: cardInfo.card.wallets)

        userWalletId = UserWalletId(with: userWalletIdSeed)
        userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: config.hasFeature(.hdWallets),
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization)
        )

        walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokenListManager: userTokenListManager,
            walletManagerFactory: walletManagerFactory
        )

        walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory()
        )

        _signer = config.tangemSigner
        accessCodeRecoveryEnabled = cardInfo.card.userSettings.isUserCodeRecoveryAllowed
        _userWalletNamePublisher = .init(cardInfo.name)
        updateCurrentSecurityOption()
        appendPersistentBlockchains()
        bind()
    }

    func setupWarnings() {
        warningsService.setupWarnings(
            for: config,
            card: cardInfo.card,
            validator: walletModelsManager.walletModels.first?.signatureCountValidator
        )
    }

    private func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userTokenListManager.update(.append(persistentBlockchains), shouldUpload: true)
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
                    onSecurityOptionChanged(isAccessCodeSet: true, isPasscodeSet: false)
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
                    onSecurityOptionChanged(isAccessCodeSet: false, isPasscodeSet: false)
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
                    onSecurityOptionChanged(isAccessCodeSet: false, isPasscodeSet: true)
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
        _signer = config.tangemSigner
        updateModel()
        // prevent save until onboarding completed
        if userWalletRepository.contains(userWallet) {
            userWalletRepository.save(userWallet)
        }
        _updatePublisher.send()
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        config.getDisabledLocalizedReason(for: feature)
    }

    private func updateModel() {
        AppLog.shared.debug("🔄 Updating Card view model")
        updateCurrentSecurityOption()

        setupWarnings()
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

extension CardViewModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}

extension CardViewModel: WalletConnectUserWalletInfoProvider {
    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }
}

// MARK: Access code recovery settings provider

extension CardViewModel: AccessCodeRecoverySettingsProvider {
    func setAccessCodeRecovery(to enabled: Bool, _ completionHandler: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let tangemSdk = makeTangemSdk()
        self.tangemSdk = tangemSdk

        tangemSdk.setUserCodeRecoveryAllowed(enabled, cardId: cardId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                cardInfo.card.userSettings.isUserCodeRecoveryAllowed = enabled
                accessCodeRecoveryEnabled = enabled
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
    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
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

    var updatePublisher: AnyPublisher<Void, Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    var tokensCount: Int? {
        walletModelsManager.walletModels.count
    }

    func initialUpdate() {
        guard !didPerformInitialUpdate else {
            AppLog.shared.debug("Initial update has been performed")
            return
        }

        didPerformInitialUpdate = true

        userTokensManager.updateUserTokens()
    }

    func updateWalletName(_ name: String) {
        cardInfo.name = name
        _userWalletNamePublisher.send(name)
    }
}

extension CardViewModel: MainHeaderInfoProvider {
    var cardHeaderImage: ImageType? { config.cardHeaderImage }

    var isUserWalletLocked: Bool { userWallet.isLocked }

    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }
}

// TODO: refactor storage to single source
extension CardViewModel: DerivationManagerDelegate {
    func onDerived(_ response: DerivationResult) {
        // tmp sync
        for updatedWallet in response {
            for derivedKey in updatedWallet.value.keys {
                cardInfo.card.wallets[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
            }
        }

        userWalletRepository.save(userWallet)
    }
}

extension CardViewModel: CardDerivableProvider {
    var cardDerivableInteractor: CardDerivable {
        // TODO: TBD. Use config?
        let shouldSkipCardId = cardInfo.card.backupStatus?.isActive ?? false
        let cardId = shouldSkipCardId ? nil : cardInfo.card.cardId
        return CardInteractor(tangemSdk: config.makeTangemSdk(), cardId: cardId)
    }
}

extension CardViewModel: TotalBalanceProviding {
    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        totalBalanceProvider.totalBalancePublisher()
    }
}
