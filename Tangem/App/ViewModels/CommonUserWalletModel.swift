//
//  CommonUserWalletModel.swift
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

class CommonUserWalletModel {
    // MARK: Services

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    let walletModelsManager: WalletModelsManager
    let userTokensManager: UserTokensManager
    let userTokenListManager: UserTokenListManager
    let keysRepository: KeysRepository
    let derivationManager: DerivationManager?
    let totalBalanceProvider: TotalBalanceProviding

    private let walletManagersRepository: WalletManagersRepository
    private let cardImageProvider = CardImageProvider()

    private var associatedCardIds: Set<String>

    var signer: TangemSigner { _signer }

    var cardId: String { cardInfo.card.cardId }

    var card: CardDTO {
        cardInfo.card
    }

    var cardPublicKey: Data { cardInfo.card.cardPublicKey }

    var supportsOnlineImage: Bool {
        config.hasFeature(.onlineImage)
    }

    var emailConfig: EmailConfig? {
        config.emailConfig
    }

    let userWalletId: UserWalletId

    private(set) var cardInfo: CardInfo
    private var tangemSdk: TangemSdk?
    var config: UserWalletConfig

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>
    private let _cardHeaderImagePublisher: CurrentValueSubject<ImageType?, Never>
    private var bag = Set<AnyCancellable>()
    private var signSubscription: AnyCancellable?

    private var _signer: TangemSigner {
        didSet {
            bindSigner()
        }
    }

    init(
        cardInfo: CardInfo,
        config: UserWalletConfig,
        userWalletId: UserWalletId,
        associatedCardIds: Set<String>,
        walletManagersRepository: WalletManagersRepository,
        walletModelsManager: WalletModelsManager,
        userTokensManager: CommonUserTokensManager,
        userTokenListManager: UserTokenListManager,
        keysRepository: KeysRepository,
        derivationManager: DerivationManager?,
        totalBalanceProvider: TotalBalanceProviding
    ) {
        self.cardInfo = cardInfo
        self.config = config
        self.userWalletId = userWalletId

        var associatedCardIds = associatedCardIds
        associatedCardIds.insert(cardInfo.card.cardId)
        self.associatedCardIds = associatedCardIds

        self.walletManagersRepository = walletManagersRepository
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.userTokenListManager = userTokenListManager
        self.keysRepository = keysRepository
        self.derivationManager = derivationManager
        self.totalBalanceProvider = totalBalanceProvider

        _signer = config.tangemSigner
        _userWalletNamePublisher = .init(cardInfo.name)
        _cardHeaderImagePublisher = .init(config.cardHeaderImage)
        appendPersistentBlockchains()
        bind()

        userTokensManager.sync {}
    }

    deinit {
        Log.debug("CommonUserWalletModel deinit 🥳🤟")
    }

    func validate() -> Bool {
        let pendingBackupManager = PendingBackupManager()
        if pendingBackupManager.fetchPendingCard(cardInfo.card.cardId) != nil {
            return false
        }

        guard validateBackup(card.backupStatus, wallets: card.wallets) else {
            return false
        }

        return true
    }

    private func validateBackup(_ backupStatus: Card.BackupStatus?, wallets: [CardDTO.Wallet]) -> Bool {
        let backupValidator = BackupValidator()
        if !backupValidator.validate(backupStatus: card.backupStatus, wallets: wallets) {
            return false
        }

        return true
    }

    private func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userTokenListManager.update(.append(persistentBlockchains), shouldUpload: true)
    }

    // MARK: - Update

    func onSigned(_ card: Card) {
        for updatedWallet in card.wallets {
            cardInfo.card.wallets[updatedWallet.publicKey]?.totalSignedHashes = updatedWallet.totalSignedHashes
            cardInfo.card.wallets[updatedWallet.publicKey]?.remainingSignatures = updatedWallet.remainingSignatures
        }

        onUpdate()
    }

    private func onUpdate() {
        AppLog.shared.debug("🔄 Updating CommonUserWalletModel with new Card")
        config = UserWalletConfigFactory(cardInfo).makeConfig()
        _cardHeaderImagePublisher.send(config.cardHeaderImage)
        _signer = config.tangemSigner
        // prevent save until onboarding completed
        if userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) != nil {
            userWalletRepository.save()
        }
        _updatePublisher.send()
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

extension CommonUserWalletModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}

// TODO: Refactor
extension CommonUserWalletModel: TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk {
        config.makeTangemSdk()
    }
}

// MARK: - UserWalletModel

extension CommonUserWalletModel: UserWalletModel {
    var name: String {
        cardInfo.name
    }

    var totalSignedHashes: Int {
        cardInfo.card.wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }

    var analyticsContextData: AnalyticsContextData {
        AnalyticsContextData(
            card: cardInfo.card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: userWalletId
        )
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
    }

    var hasBackupCards: Bool {
        cardInfo.card.backupStatus?.isActive ?? false
    }

    var cardsCount: Int {
        config.cardsCount
    }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var backupInput: OnboardingInput? {
        let factory = OnboardingInputFactory(
            cardInfo: cardInfo,
            userWalletModel: self,
            sdkFactory: config,
            onboardingStepsBuilderFactory: config,
            pushNotificationsInteractor: pushNotificationsInteractor
        )

        return factory.makeBackupInput()
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    var tokensCount: Int? {
        walletModelsManager.walletModels.count
    }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> {
        let artwork: CardArtwork

        if let artworkInfo = cardImageProvider.cardArtwork(for: cardInfo.card.cardId)?.artworkInfo {
            artwork = .artwork(artworkInfo)
        } else {
            artwork = .notLoaded
        }

        return cardImageProvider.loadImage(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            artwork: artwork
        )
    }

    func updateWalletName(_ name: String) {
        cardInfo.name = name
        _userWalletNamePublisher.send(name)
        userWalletRepository.save()
    }

    func onBackupUpdate(type: BackupUpdateType) {
        switch type {
        case .primaryCardBackuped(let card):
            for updatedWallet in card.wallets {
                cardInfo.card.wallets[updatedWallet.publicKey]?.hasBackup = updatedWallet.hasBackup
            }

            cardInfo.card.settings = CardDTO.Settings(settings: card.settings)
            cardInfo.card.isAccessCodeSet = card.isAccessCodeSet
            cardInfo.card.backupStatus = card.backupStatus
            onUpdate()
        case .backupCompleted:
            // we have to read an actual status from backup validator
            _updatePublisher.send()
        }

        // update for ring image
        _cardHeaderImagePublisher.send(config.cardHeaderImage)
    }

    func addAssociatedCard(_ cardId: String) {
        let cardInfo = CardInfo(card: card, walletData: .none, name: "")
        guard let userWalletId = UserWalletIdFactory().userWalletId(from: cardInfo),
              userWalletId == self.userWalletId else {
            return
        }

        if !associatedCardIds.contains(cardId) {
            associatedCardIds.insert(cardId)
        }
    }
}

extension CommonUserWalletModel: MainHeaderSupplementInfoProvider {
    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { _cardHeaderImagePublisher.removeDuplicates().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }
}

extension CommonUserWalletModel: MainHeaderUserWalletStateInfoProvider {
    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { userTokenListManager.userTokensList.entries.isEmpty }
}

// TODO: refactor storage to single source
extension CommonUserWalletModel: DerivationManagerDelegate {
    func onDerived(_ response: DerivationResult) {
        // tmp sync
        for updatedWallet in response {
            for derivedKey in updatedWallet.value.keys {
                cardInfo.card.wallets[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
            }
        }

        userWalletRepository.save()
    }
}

extension CommonUserWalletModel: KeysDerivingProvider {
    var keysDerivingInteractor: KeysDeriving {
        KeysDerivingCardInteractor(with: cardInfo)
    }
}

extension CommonUserWalletModel: TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceProvider.totalBalancePublisher
    }
}

extension CommonUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        return AnalyticsContextData(
            card: card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: userWalletId
        )
    }
}

extension CommonUserWalletModel: UserWalletSerializable {
    func serialize() -> StoredUserWallet {
        let name = name.isEmpty ? config.cardName : name

        let newStoredUserWallet = StoredUserWallet(
            userWalletId: userWalletId.value,
            name: name,
            card: cardInfo.card,
            associatedCardIds: associatedCardIds,
            walletData: cardInfo.walletData,
            artwork: cardInfo.artwork.artworkInfo
        )

        return newStoredUserWallet
    }
}
