//
//  UserWalletRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import TangemSdk

class CommonUserWalletRepository: UserWalletRepository {
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.walletConnectService) private var walletConnectServiceProvider: WalletConnectService
    @Injected(\.saltPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.exchangeServiceConfigurator) var exchangeService: ExchangeServiceConfigurator
    @Injected(\.analyticsContext) var analyticsContext: AnalyticsContext

    var selectedModel: CardViewModel? {
        return models.first {
            $0.userWallet?.userWalletId == selectedUserWalletId
        }
    }

    var selectedUserWalletId: Data?

    var isEmpty: Bool {
        userWallets.isEmpty
    }

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private(set) var models = [CardViewModel]()

    private(set) var isLocked: Bool = true

    private var userWallets: [UserWallet] = []

    private var encryptionKeyByUserWalletId: [Data: SymmetricKey] = [:]

    private let encryptionKeyStorage = UserWalletEncryptionKeyStorage()

    private var backupService: BackupService {
        backupServiceProvider.backupService
    }

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    private let minimizedAppTimer = MinimizedAppTimer(interval: 5 * 60)

    private var bag: Set<AnyCancellable> = .init()

    init() {
        bind()
    }

    deinit {
        AppLog.shared.debug("UserWalletRepository deinit")
    }

    func bind() {
        minimizedAppTimer
            .timer
            .filter { [weak self] in
                guard let self else { return false }

                let allWalletsLocked = self.userWallets.allSatisfy { $0.isLocked }
                return !self.isLocked || !allWalletsLocked
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.lock(reason: .loggedOut)
            }
            .store(in: &bag)
    }

    private func scanPublisher() -> AnyPublisher<UserWalletRepositoryResult?, Never> {
        scanInternal()
            .eraseError()
            .flatMap { [weak self] response -> AnyPublisher<AppScanTaskResponse, Error> in
                guard let self else {
                    return .justWithError(output: response)
                }

                let saltPayUtil = SaltPayUtil()

                if saltPayUtil.isBackupCard(cardId: response.card.cardId) {
                    if response.card.wallets.isEmpty {
                        return .anyFail(error: SaltPayRegistratorError.emptyBackupCardScanned)
                    } else {
                        return .justWithError(output: response)
                    }
                }

                if !saltPayUtil.isPrimaryCard(batchId: response.card.batchId) {
                    self.saltPayRegistratorProvider.reset()
                    return .justWithError(output: response)
                }

                if let wallet = response.card.wallets.first {
                    try? self.saltPayRegistratorProvider.initialize(
                        cardId: response.card.cardId,
                        walletPublicKey: wallet.publicKey,
                        cardPublicKey: response.card.cardPublicKey
                    )
                }

                guard let saltPayRegistrator = self.saltPayRegistratorProvider.registrator else {
                    return .justWithError(output: response)
                }

                return saltPayRegistrator.updatePublisher()
                    .map { _ in
                        return response
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] response -> AnyPublisher<UserWalletRepositoryResult?, Error> in
                guard let self else {
                    return .justWithError(output: nil)
                }

                self.failedCardScanTracker.resetCounter()
                self.sendEvent(.scan(isScanning: false))

                let cardDTO = CardDTO(card: response.card)
                self.didScan(card: cardDTO, walletData: response.walletData)
                let cardModel = self.processScan(response.getCardInfo())
                Analytics.endLoggingCardScan()
                let onboardingInput = cardModel.onboardingInput
                if onboardingInput.steps.needOnboarding {
                    cardModel.userWalletModel?.updateAndReloadWalletModels()

                    return Just(UserWalletRepositoryResult.onboarding(onboardingInput))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                return Just(.success(cardModel))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .catch { [weak self] error -> Just<UserWalletRepositoryResult?> in
                guard let self else {
                    return Just(nil)
                }

                AppLog.shared.error(error)
                self.failedCardScanTracker.recordFailure()
                self.sendEvent(.scan(isScanning: false))

                if error is SaltPayRegistratorError {
                    return Just(UserWalletRepositoryResult.error(error))
                }

                if self.failedCardScanTracker.shouldDisplayAlert {
                    return Just(UserWalletRepositoryResult.troubleshooting)
                }

                switch error.toTangemSdkError() {
                case .unknownError, .cardVerificationFailed:
                    return Just(UserWalletRepositoryResult.error(error))
                default:
                    return Just(nil)
                }
            }
            .eraseToAnyPublisher()
    }

    private func scanInternal() -> AnyPublisher<AppScanTaskResponse, TangemSdkError> {
        Analytics.log(.readyToScan)

        let oldConfig = sdkProvider.sdk.config
        var config = TangemSdkConfigFactory().makeDefaultConfig()

        if AppSettings.shared.saveUserWallets {
            config.accessCodeRequestPolicy = .alwaysWithBiometrics
        } else {
            resetServices()
        }

        sdkProvider.setup(with: config)

        sendEvent(.scan(isScanning: true))

        return sdkProvider.sdk
            .startSessionPublisher(with: AppScanTask())
            .handleEvents(receiveCompletion: { [weak self] error in
                self?.sdkProvider.setup(with: oldConfig)
            })
            .eraseToAnyPublisher()
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        switch method {
        case .biometry:
            unlockWithBiometry(completion: completion)
        case .card(let userWallet):
            unlockWithCard(userWallet, completion: completion)
        }
    }

    func didScan(card: CardDTO, walletData: DefaultWalletData) {
        let cardId = card.cardId

        let cardInfo = CardInfo(card: card, walletData: walletData, name: "")

        guard
            let userWalletId = UserWalletIdFactory().userWalletId(from: cardInfo)?.value,
            card.hasWallets,
            var userWallet = userWallets.first(where: { $0.userWalletId == userWalletId }),
            !userWallet.associatedCardIds.contains(cardId)
        else {
            return
        }

        userWallet.associatedCardIds.insert(cardId)
        save(userWallet)
    }

    func contains(_ userWallet: UserWallet) -> Bool {
        userWallets.contains { $0.userWalletId == userWallet.userWalletId }
    }

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let cardModel):
                    guard let userWallet = cardModel.userWallet else { return }

                    if !self.contains(userWallet) {
                        self.save(userWallet)
                        completion(result)
                    } else {
                        completion(.error(UserWalletRepositoryError.duplicateWalletAdded))
                        return
                    }

                    self.setSelectedUserWalletId(userWallet.userWalletId, reason: .inserted)
                default:
                    completion(result)
                }
            }
            .store(in: &bag)
    }

    func save(_ userWallet: UserWallet) {
        if models.isEmpty && !userWallets.isEmpty {
            loadModels()
        }

        if let index = userWallets.firstIndex(where: { $0.userWalletId == userWallet.userWalletId }) {
            userWallets[index] = userWallet
        } else {
            userWallets.append(userWallet)
        }

        encryptionKeyStorage.add(userWallet)

        saveUserWallets(userWallets)

        let userWalletModel: UserWalletModel?
        if let index = models.firstIndex(where: { $0.userWallet?.userWalletId == userWallet.userWalletId }) {
            models[index].setUserWallet(userWallet)
            userWalletModel = models[index].userWalletModel
        } else {
            let newModel = CardViewModel(userWallet: userWallet)
            newModel.userWalletModel?.initialUpdate()

            models.append(newModel)
            userWalletModel = newModel.userWalletModel

            sendEvent(.inserted(userWallet: userWallet))
        }

        guard let userWalletModel else { return }

        sendEvent(.updated(userWalletModel: userWalletModel))

        if userWallets.isEmpty || selectedUserWalletId == nil {
            setSelectedUserWalletId(userWallet.userWalletId, reason: .inserted)
        }
    }

    func updateSelection() {
        initializeServicesForSelectedModel()
    }

    func logoutIfNeeded() {
        if userWallets.contains(where: { !$0.isLocked }) {
            return
        }

        lock(reason: .nothingToDisplay)
    }

    func setSelectedUserWalletId(_ userWalletId: Data?, reason: UserWalletRepositorySelectionChangeReason) {
        setSelectedUserWalletId(userWalletId, unlockIfNeeded: true, reason: reason)
    }

    func setSelectedUserWalletId(_ userWalletId: Data?, unlockIfNeeded: Bool, reason: UserWalletRepositorySelectionChangeReason) {
        guard selectedUserWalletId != userWalletId else { return }

        if userWalletId == nil {
            selectedUserWalletId = nil
            AppSettings.shared.selectedUserWalletId = Data()
            return
        }

        guard let userWallet = userWallets.first(where: {
            $0.userWalletId == userWalletId
        }) else {
            return
        }

        let updateSelection: (UserWallet) -> Void = { [weak self] userWallet in
            self?.selectedUserWalletId = userWallet.userWalletId
            AppSettings.shared.selectedUserWalletId = userWallet.userWalletId
            self?.initializeServicesForSelectedModel()
            self?.selectedModel?.userWalletModel?.initialUpdate()
            self?.sendEvent(.selected(userWallet: userWallet, reason: reason))
        }

        if !userWallet.isLocked || !unlockIfNeeded {
            updateSelection(userWallet)
            return
        }

        unlock(with: .card(userWallet: userWallet)) { [weak self] result in
            guard
                let self,
                case .success = result,
                let selectedModel = self.models.first(where: { $0.userWallet?.userWalletId == userWallet.userWalletId }),
                let userWallet = selectedModel.userWallet
            else {
                return
            }

            updateSelection(userWallet)
        }
    }

    func delete(_ userWallet: UserWallet, logoutIfNeeded shouldAutoLogout: Bool) {
        let userWalletId = userWallet.userWalletId
        encryptionKeyByUserWalletId[userWalletId] = nil
        userWallets.removeAll { $0.userWalletId == userWalletId }
        models.removeAll { $0.userWalletId == userWalletId }

        encryptionKeyStorage.delete(userWallet)
        saveUserWallets(userWallets)

        if selectedUserWalletId == userWalletId {
            let sortedModels = models.sorted { $0.isMultiWallet && !$1.isMultiWallet }
            let unlockedModels = sortedModels.filter { model in
                guard let userWallet = userWallets.first(where: { $0.userWalletId == model.userWalletId }) else { return false }

                return !userWallet.isLocked
            }

            if let firstUnlockedModel = unlockedModels.first {
                setSelectedUserWalletId(firstUnlockedModel.userWalletId, reason: .deleted)
            } else if let firstModel = sortedModels.first {
                setSelectedUserWalletId(firstModel.userWalletId, unlockIfNeeded: false, reason: .deleted)
            } else {
                setSelectedUserWalletId(nil, reason: .deleted)
            }

            if shouldAutoLogout {
                logoutIfNeeded()
            }
        }

        sendEvent(.deleted(userWalletId: userWalletId))
    }

    func lock(reason: UserWalletRepositoryLockReason) {
        discardSensitiveData()

        resetServices()

        sendEvent(.locked(reason: reason))
    }

    func clear() {
        clearUserWallets()
        discardSensitiveData()

        setSelectedUserWalletId(nil, reason: .deleted)
    }

    private func clearUserWallets() {
        let userWalletRepositoryUtil = UserWalletRepositoryUtil()
        userWalletRepositoryUtil.saveUserWallets([])
        userWalletRepositoryUtil.removePublicDataEncryptionKey()

        encryptionKeyStorage.clear()
    }

    private func discardSensitiveData() {
        isLocked = true
        encryptionKeyByUserWalletId = [:]
        models = []
        userWallets = savedUserWallets(withSensitiveData: false)
    }

    // TODO: refactor
    private func resetServices() {
        walletConnectServiceProvider.reset()
        analyticsContext.clearContext()
    }

    private func initializeServices(for cardModel: CardViewModel, cardInfo: CardInfo) {
        if let userWalletId = cardModel.userWalletId {
            let contextData = AnalyticsContextData(
                card: cardInfo.card,
                productType: cardModel.productType,
                userWalletId: userWalletId,
                embeddedEntry: cardModel.embeddedEntry
            )

            analyticsContext.setupContext(with: contextData)
        }

        if let primaryCard = cardInfo.primaryCard {
            backupServiceProvider.backupService.setPrimaryCard(primaryCard)
        }

        tangemApiService.setAuthData(cardInfo.card.tangemApiAuthData)
        exchangeService.configure(for: cardModel.exchangeServiceEnvironment)
        walletConnectServiceProvider.initialize(with: cardModel)
    }

    private func processScan(_ cardInfo: CardInfo) -> CardViewModel {
        resetServices()

        // TODO: Remove CardViewModel from here, use CardInfo
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let cardModel = CardViewModel(cardInfo: cardInfo, config: config)

        initializeServices(for: cardModel, cardInfo: cardInfo)

        // Updating the config file every time a card is scanned when wallets are NOT being saved.
        // This is done to avoid unnecessary changes in SDK config when the user scans an empty card
        // (that would open onboarding) and then immediately close it.
        if !AppSettings.shared.saveUserWallets {
            cardModel.userWalletModel?.initialUpdate() // TODO: fixme
            cardModel.updateSdkConfig()
        }

        return cardModel
    }

    private func unlockWithBiometry(completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        encryptionKeyStorage.fetch { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .failure(let error):
                    completion(.error(error))
                case .success(let keys):
                    self.encryptionKeyByUserWalletId = keys
                    self.userWallets = self.savedUserWallets(withSensitiveData: true)
                    self.loadModels()
                    self.initializeServicesForSelectedModel()
                    self.selectedModel?.userWalletModel?.initialUpdate()
                    self.isLocked = false

                    if let selectedModel = self.selectedModel {
                        completion(.success(selectedModel))
                    } else {
                        completion(nil) // TODO: throw error?
                    }
                }
            }
        }
    }

    private func unlockWithCard(_ requiredUserWallet: UserWallet?, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard
                    let self,
                    case .success(let cardModel) = result,
                    AppSettings.shared.saveUserWallets
                else {
                    self?.isLocked = false
                    completion(result)
                    return
                }

                guard
                    let scannedUserWallet = cardModel.userWallet,
                    let encryptionKey = UserWalletEncryptionKeyFactory().encryptionKey(from: cardModel.cardInfo)
                else {
                    completion(.error(TangemSdkError.cardError))
                    return
                }

                if let requiredUserWallet,
                   scannedUserWallet.userWalletId != requiredUserWallet.userWalletId {
                    completion(.error(TangemSdkError.cardError))
                    return
                }

                self.encryptionKeyByUserWalletId[scannedUserWallet.userWalletId] = encryptionKey.symmetricKey

                if self.models.isEmpty {
                    self.loadModels()
                }

                let savedUserWallet: UserWallet
                if self.contains(scannedUserWallet) {
                    guard let userWallet = self.savedUserWallet(with: scannedUserWallet.userWalletId) else { return }

                    self.loadModel(for: userWallet)
                    savedUserWallet = userWallet
                } else {
                    self.save(scannedUserWallet)
                    savedUserWallet = scannedUserWallet
                }

                guard
                    let cardModel = self.models.first(where: { $0.userWalletId == savedUserWallet.userWalletId }),
                    let userWalletModel = cardModel.userWalletModel
                else {
                    return
                }

                self.setSelectedUserWalletId(savedUserWallet.userWalletId, reason: .userSelected)
                self.initializeServicesForSelectedModel()
                self.selectedModel?.userWalletModel?.initialUpdate()
                self.isLocked = self.userWallets.contains { $0.isLocked }

                self.sendEvent(.updated(userWalletModel: userWalletModel))

                completion(.success(cardModel))
            }
            .store(in: &bag)
    }

    private func loadModels() {
        let models = userWallets.map {
            CardViewModel(userWallet: $0)
        }
        self.models = models
    }

    private func loadModel(for userWallet: UserWallet) {
        guard let index = userWallets.firstIndex(where: { $0.userWalletId == userWallet.userWalletId }) else { return }

        userWallets[index] = userWallet

        guard index < models.count else { return }

        let cardModel = CardViewModel(userWallet: userWallet)

        models[index] = cardModel
    }

    private func initializeServicesForSelectedModel() {
        guard let selectedModel else { return }

        let cardInfo = selectedModel.cardInfo
        resetServices()
        initializeServices(for: selectedModel, cardInfo: cardInfo)

        // Updating the config file every time selected UserWallet is changed WHEN wallets are being saved.
        selectedModel.updateSdkConfig()
    }

    private func sendEvent(_ event: UserWalletRepositoryEvent) {
        eventSubject.send(event)
    }

    private func savedUserWallets(withSensitiveData loadSensitiveData: Bool) -> [UserWallet] {
        let keys = loadSensitiveData ? encryptionKeyByUserWalletId : [:]
        return UserWalletRepositoryUtil().savedUserWallets(encryptionKeyByUserWalletId: keys)
    }

    private func savedUserWallet(with userWalletId: Data) -> UserWallet? {
        let keys = encryptionKeyByUserWalletId.filter { $0.key == userWalletId }
        let userWallets = UserWalletRepositoryUtil().savedUserWallets(encryptionKeyByUserWalletId: keys)
        return userWallets.first { $0.userWalletId == userWalletId }
    }

    private func saveUserWallets(_ userWallets: [UserWallet]) {
        UserWalletRepositoryUtil().saveUserWallets(userWallets)
    }
}

extension CommonUserWalletRepository {
    func initialize() {
        // Removing UserWallet-related data from Keychain
        if AppSettings.shared.numberOfLaunches == 1 {
            AppLog.shared.debug("Clean CommonUserWalletRepository")
            clearUserWallets()
        }

        let savedSelectedUserWalletId = AppSettings.shared.selectedUserWalletId
        selectedUserWalletId = savedSelectedUserWalletId.isEmpty ? nil : savedSelectedUserWalletId

        userWallets = savedUserWallets(withSensitiveData: false)
    }
}
