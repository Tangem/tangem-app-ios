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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.walletConnectService) private var walletConnectService: WalletConnectService
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.analyticsContext) var analyticsContext: AnalyticsContext

    var selectedModel: UserWalletModel? {
        return models.first {
            $0.userWalletId.value == selectedUserWalletId
        }
    }

    var selectedUserWalletId: Data?

    var selectedIndexUserWalletModel: Int? {
        models.firstIndex {
            $0.userWallet?.userWalletId == selectedUserWalletId
        }
    }

    var hasSavedWallets: Bool {
        !savedUserWallets(withSensitiveData: false).isEmpty
    }

    var isEmpty: Bool {
        userWallets.isEmpty
    }

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private(set) var models = [UserWalletModel]()
    private(set) var userWallets: [StoredUserWallet] = []

    var isLocked: Bool { userWallets.contains { $0.isLocked } }

    private var encryptionKeyByUserWalletId: [Data: SymmetricKey] = [:]

    private let encryptionKeyStorage = UserWalletEncryptionKeyStorage()

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    private let minimizedAppTimer = MinimizedAppTimer(interval: 5 * 60)

    private var sdk: TangemSdk?

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

                return !isLocked
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.lock(reason: .loggedOut)
            }
            .store(in: &bag)
    }

    private func scanPublisher() -> AnyPublisher<UserWalletRepositoryResult?, Never> {
        scanInternal()
            .eraseError()
            .flatMap { [weak self] response -> AnyPublisher<UserWalletRepositoryResult?, Error> in
                guard let self else {
                    return .justWithError(output: nil)
                }

                failedCardScanTracker.resetCounter()
                sendEvent(.scan(isScanning: false))

                let cardDTO = CardDTO(card: response.card)
                didScan(card: cardDTO, walletData: response.walletData)
                var cardInfo = response.getCardInfo()
                resetServices()
                initializeAnalyticsContext(with: cardInfo)
                let config = UserWalletConfigFactory(cardInfo).makeConfig()
                Analytics.endLoggingCardScan()

                cardInfo.name = config.cardName

                let userWalletModel = CommonUserWalletModel(cardInfo: cardInfo)
                if let userWalletModel {
                    initializeServices(for: userWalletModel)
                }

                let factory = OnboardingInputFactory(
                    cardInfo: cardInfo,
                    userWalletModel: userWalletModel,
                    sdkFactory: config,
                    onboardingStepsBuilderFactory: config
                )

                if let onboardingInput = factory.makeOnboardingInput() {
                    return .justWithError(output: .onboarding(onboardingInput))
                } else if let userWalletModel {
                    return .justWithError(output: .success(userWalletModel))
                }

                return .anyFail(error: "Unknown error")
            }
            .catch { [weak self] error -> Just<UserWalletRepositoryResult?> in
                guard let self else {
                    return Just(nil)
                }

                AppLog.shared.error(error)
                failedCardScanTracker.recordFailure()
                sendEvent(.scan(isScanning: false))

                if failedCardScanTracker.shouldDisplayAlert {
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
        var config = TangemSdkConfigFactory().makeDefaultConfig()

        if AppSettings.shared.saveUserWallets {
            config.accessCodeRequestPolicy = .alwaysWithBiometrics
        }

        let sdk = TangemSdkDefaultFactory().makeTangemSdk(with: config)
        self.sdk = sdk
        sendEvent(.scan(isScanning: true))

        return sdk
            .startSessionPublisher(with: AppScanTask())
            .eraseToAnyPublisher()
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        switch method {
        case .biometry:
            unlockWithBiometry(completion: completion)
        case .card(let userWalletId):
            unlockWithCard(userWalletId, completion: completion)
        }
    }

    func addOrScan(completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        if AppSettings.shared.saveUserWallets {
            add(completion)
        } else {
            unlockWithCard(nil, completion: completion)
        }
    }

    func didScan(card: CardDTO, walletData: DefaultWalletData) {
        let cardId = card.cardId

        let cardInfo = CardInfo(card: card, walletData: walletData, name: "")

        guard
            let userWalletId = UserWalletIdFactory().userWalletId(from: cardInfo)?.value,
            var userWallet = userWallets.first(where: { $0.userWalletId == userWalletId }),
            !userWallet.associatedCardIds.contains(cardId)
        else {
            return
        }

        userWallet.associatedCardIds.insert(cardId)
        save(userWallet)
    }

    func contains(_ userWallet: StoredUserWallet) -> Bool {
        userWallets.contains { $0.userWalletId == userWallet.userWalletId }
    }

    func add(_ userWalletModel: UserWalletModel) {
        if AppSettings.shared.saveUserWallets {
            save(userWalletModel)
        } else {
            models = [userWalletModel]
            if let userWallet = userWalletModel.userWallet {
                userWallets = [userWallet]
            }
        }

        setSelectedUserWalletId(userWalletModel.userWalletId.value, reason: .inserted)
    }

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let userWalletModel):
                    guard let userWallet = userWalletModel.userWallet else {
                        return
                    }

                    if !contains(userWallet) {
                        save(userWalletModel)
                        completion(result)
                    } else {
                        completion(.error(UserWalletRepositoryError.duplicateWalletAdded))
                        return
                    }

                    setSelectedUserWalletId(userWallet.userWalletId, reason: .inserted)
                default:
                    completion(result)
                }
            }
            .store(in: &bag)
    }

    // TODO: refactor
    func save(_ userWalletModel: UserWalletModel) {
        if models.isEmpty, !userWallets.isEmpty {
            loadModels()
        }

        if let index = models.firstIndex(where: { $0.userWalletId == userWalletModel.userWalletId }) {
            models[index] = userWalletModel
        } else {
            models.append(userWalletModel)
            sendEvent(.inserted(userWalletId: userWalletModel.userWalletId))
        }

        if let userWallet = userWalletModel.userWallet {
            save(userWallet)
        }
    }

    func setSaving(_ enabled: Bool) {
        if enabled {
            if let selectedModel {
                save(selectedModel)
            }
        } else {
            clearNonSelectedUserWallets()
        }
    }

    func save() {}

    func save(_ userWallet: StoredUserWallet) {
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
        if let index = models.firstIndex(where: { $0.userWalletId.value == userWallet.userWalletId }) {
            userWalletModel = models[index]
            userWalletModel?.updateWalletName(userWallet.name)
        } else {
            userWalletModel = nil
        }

        guard let userWalletModel else { return }

        sendEvent(.updated(userWalletId: userWalletModel.userWalletId))

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

        let updateSelection: (StoredUserWallet) -> Void = { [weak self] userWallet in
            self?.selectedUserWalletId = userWallet.userWalletId
            AppSettings.shared.selectedUserWalletId = userWallet.userWalletId
            self?.initializeServicesForSelectedModel()
            self?.sendEvent(.selected(userWalletId: UserWalletId(value: userWallet.userWalletId), reason: reason))
        }

        if !userWallet.isLocked || !unlockIfNeeded {
            updateSelection(userWallet)
            return
        }

        unlock(with: .card(userWalletId: UserWalletId(value: userWallet.userWalletId))) { [weak self] result in
            guard
                let self,
                case .success = result,
                let selectedModel = models.first(where: { $0.userWalletId.value == userWallet.userWalletId }),
                let userWallet = selectedModel.userWallet
            else {
                return
            }

            updateSelection(userWallet)
        }
    }

    func delete(_ userWalletId: UserWalletId, logoutIfNeeded shouldAutoLogout: Bool) {
        guard let userWallet = models.first(where: { $0.userWalletId == userWalletId })?.userWallet else {
            return
        }

        if selectedUserWalletId == userWalletId.value {
            resetServices()
        }

        let targetIndex: Int
        if let currentIndex = models.firstIndex(where: { $0.userWalletId == userWalletId }) {
            targetIndex = currentIndex > 0 ? (currentIndex - 1) : 0
        } else {
            targetIndex = 0
        }

        encryptionKeyByUserWalletId[userWalletId.value] = nil
        userWallets.removeAll { $0.userWalletId == userWalletId.value }
        models.removeAll { $0.userWalletId == userWalletId }

        encryptionKeyStorage.delete(userWallet)
        saveUserWallets(userWallets)

        if !models.isEmpty {
            let newModel = models[targetIndex]
            setSelectedUserWalletId(newModel.userWalletId.value, unlockIfNeeded: false, reason: .deleted)
        }

        if shouldAutoLogout {
            logoutIfNeeded()
        }

        walletConnectService.disconnectAllSessionsForUserWallet(with: userWalletId.stringValue)
        sendEvent(.deleted(userWalletIds: [userWalletId]))
    }

    func lock(reason: UserWalletRepositoryLockReason) {
        discardSensitiveData()

        resetServices()

        sendEvent(.locked(reason: reason))
    }

    func clearNonSelectedUserWallets() {
        let selectedModel = selectedModel
        let otherUserWallets = userWallets.filter { $0.userWalletId != selectedUserWalletId }

        clearUserWalletStorage()
        discardSensitiveData(except: selectedModel)

        sendEvent(.deleted(userWalletIds: otherUserWallets.map { UserWalletId(value: $0.userWalletId) }))
    }

    func initializeServices(for userWalletModel: UserWalletModel) {
        analyticsContext.setupContext(with: userWalletModel.analyticsContextData)
        tangemApiService.setAuthData(userWalletModel.tangemApiAuthData)
        walletConnectService.initialize(with: userWalletModel)
    }

    // we can initialize it right after scan for more accurate analytics
    func initializeAnalyticsContext(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let userWalletId = config.userWalletIdSeed.map { UserWalletId(with: $0).value }
        let contextData = AnalyticsContextData(
            card: cardInfo.card,
            productType: config.productType,
            userWalletId: userWalletId,
            embeddedEntry: config.embeddedBlockchain
        )

        analyticsContext.setupContext(with: contextData)
    }

    private func clearUserWalletStorage() {
        let userWalletRepositoryUtil = UserWalletRepositoryUtil()
        userWalletRepositoryUtil.saveUserWallets([])
        userWalletRepositoryUtil.removePublicDataEncryptionKey()

        encryptionKeyStorage.clear()
    }

    private func discardSensitiveData(except userWalletModelToKeep: UserWalletModel? = nil) {
        encryptionKeyByUserWalletId = [:]

        if let userWalletModelToKeep {
            models = [userWalletModelToKeep]
            if let userWallet = userWalletModelToKeep.userWallet {
                userWallets = [userWallet]
            }
        } else {
            models = []
            userWallets = []
        }
    }

    // TODO: refactor
    private func resetServices() {
        walletConnectService.reset()
        analyticsContext.clearContext()
    }

    private func unlockWithBiometry(completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        encryptionKeyStorage.fetch { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .failure(let error):
                    completion(.error(error))
                case .success(let keys):
                    if keys.isEmpty {
                        // clean to prevent double tap
                        AccessCodeRepository().clear()
                        completion(.error(UserWalletRepositoryError.biometricsChanged))
                        return
                    }

                    self.encryptionKeyByUserWalletId = keys
                    self.userWallets = self.savedUserWallets(withSensitiveData: true)
                    self.loadModels()
                    self.initializeServicesForSelectedModel()

                    self.sendEvent(.biometryUnlocked)

                    if let selectedModel = self.selectedModel {
                        if keys.count == self.userWallets.count {
                            completion(.success(selectedModel))
                        } else {
                            completion(.partial(selectedModel, UserWalletRepositoryError.biometricsChanged))
                        }
                    } else {
                        completion(nil) // TODO: throw error?
                    }
                }
            }
        }
    }

    private func unlockWithCard(_ requiredUserWalletId: UserWalletId?, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard
                    let self,
                    case .success(let userWalletModel) = result
                else {
                    completion(result)
                    return
                }

                if !AppSettings.shared.saveUserWallets {
                    if let userWallet = userWalletModel.userWallet {
                        userWallets = [userWallet]
                    }

                    models = [userWalletModel]
                    selectedUserWalletId = userWalletModel.userWalletId.value
                    sendEvent(.replaced(userWalletId: userWalletModel.userWalletId))
                    completion(result)
                    return
                }

                guard let scannedUserWallet = userWalletModel.userWallet,
                      let seed = userWalletModel.config.userWalletIdSeed,
                      let encryptionKey = UserWalletEncryptionKeyFactory().encryptionKey(from: seed) else {
                    completion(.error(TangemSdkError.cardError))
                    return
                }

                if let requiredUserWalletId, scannedUserWallet.userWalletId != requiredUserWalletId.value {
                    completion(.error(UserWalletRepositoryError.cardWithWrongUserWalletIdScanned))
                    return
                }

                encryptionKeyByUserWalletId[scannedUserWallet.userWalletId] = encryptionKey.symmetricKey
                // We have to refresh a key on every scan because we are unable to check presence of the key
                encryptionKeyStorage.refreshEncryptionKey(encryptionKey.symmetricKey, for: scannedUserWallet.userWalletId)

                // We need to load UserWallets becaues if repository is logged out all locked UserWallets were cleaned from
                // memory and they won't be restored while scanning card.
                loadUserWalletsNotSensitiveDataIfEmpty()

                if models.isEmpty {
                    loadModels()
                }

                let savedUserWallet: StoredUserWallet
                if contains(scannedUserWallet) {
                    guard let userWallet = self.savedUserWallet(with: scannedUserWallet.userWalletId) else { return }

                    loadModel(for: userWallet)
                    savedUserWallet = userWallet
                } else {
                    save(userWalletModel)
                    savedUserWallet = scannedUserWallet
                }

                guard
                    let userWalletModel = models.first(where: { $0.userWalletId.value == savedUserWallet.userWalletId })
                else {
                    return
                }

                setSelectedUserWalletId(savedUserWallet.userWalletId, reason: .userSelected)
                initializeServicesForSelectedModel()

                sendEvent(.updated(userWalletId: userWalletModel.userWalletId))
                completion(.success(userWalletModel))
            }
            .store(in: &bag)
    }

    private func loadUserWalletsNotSensitiveDataIfEmpty() {
        guard userWallets.isEmpty else {
            return
        }

        userWallets = savedUserWallets(withSensitiveData: false)
    }

    private func loadModels() {
        let models: [UserWalletModel] = userWallets.map { userWalletStorageItem in
            if let userWallet = CommonUserWalletModel(userWallet: userWalletStorageItem) {
                return userWallet
            } else {
                return LockedUserWalletModel(with: userWalletStorageItem)
            }
        }

        self.models = models
    }

    private func loadModel(for userWallet: StoredUserWallet) {
        guard let index = userWallets.firstIndex(where: { $0.userWalletId == userWallet.userWalletId }) else { return }

        userWallets[index] = userWallet

        guard index < models.count,
              let userWalletModel = CommonUserWalletModel(userWallet: userWallet) else {
            return
        }

        models[index] = userWalletModel
    }

    private func initializeServicesForSelectedModel() {
        resetServices()

        guard let selectedModel else { return }

        initializeServices(for: selectedModel)
    }

    private func sendEvent(_ event: UserWalletRepositoryEvent) {
        eventSubject.send(event)
    }

    private func savedUserWallets(withSensitiveData loadSensitiveData: Bool) -> [StoredUserWallet] {
        let keys = loadSensitiveData ? encryptionKeyByUserWalletId : [:]
        return UserWalletRepositoryUtil().savedUserWallets(encryptionKeyByUserWalletId: keys)
    }

    private func savedUserWallet(with userWalletId: Data) -> StoredUserWallet? {
        let keys = encryptionKeyByUserWalletId.filter { $0.key == userWalletId }
        let userWallets = UserWalletRepositoryUtil().savedUserWallets(encryptionKeyByUserWalletId: keys)
        return userWallets.first { $0.userWalletId == userWalletId }
    }

    private func saveUserWallets(_ userWallets: [StoredUserWallet]) {
        UserWalletRepositoryUtil().saveUserWallets(userWallets)
    }
}

extension CommonUserWalletRepository {
    func initialize() {
        let savedSelectedUserWalletId = AppSettings.shared.selectedUserWalletId
        selectedUserWalletId = savedSelectedUserWalletId.isEmpty ? nil : savedSelectedUserWalletId

        loadUserWalletsNotSensitiveDataIfEmpty()
        AppLog.shared.debug("CommonUserWalletRepository initialized")
    }

    func initialClean() {
        // Removing UserWallet-related data from Keychain
        AppLog.shared.debug("Clean CommonUserWalletRepository")
        clearUserWalletStorage()
    }
}

extension UserWalletModel {
    var userWallet: StoredUserWallet? {
        (self as? UserWalletSerializable)?.serialize()
    }
}
