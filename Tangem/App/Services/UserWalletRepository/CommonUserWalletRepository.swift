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
            $0.userWalletId == selectedUserWalletId
        }
    }

    var selectedUserWalletId: UserWalletId?

    var selectedIndexUserWalletModel: Int? {
        models.firstIndex {
            $0.userWalletId == selectedUserWalletId
        }
    }

    var hasSavedWallets: Bool {
        !savedUserWallets(withSensitiveData: false).isEmpty
    }

    var isEmpty: Bool {
        models.isEmpty
    }

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private(set) var models = [UserWalletModel]()

    var isLocked: Bool { models.contains { $0.isUserWalletLocked } }

    private var encryptionKeyByUserWalletId: [UserWalletId: UserWalletEncryptionKey] = [:]

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

                var cardInfo = response.getCardInfo()
                updateAssociatedCard(for: cardInfo)
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

    private func updateAssociatedCard(for cardInfo: CardInfo) {
        guard let userWalletId = UserWalletIdFactory().userWalletId(from: cardInfo),
              let existing = models.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        existing.addAssociatedCard(cardInfo.card, validationMode: .light)
        save()
    }

    func add(_ userWalletModel: UserWalletModel) {
        if AppSettings.shared.saveUserWallets {
            save(userWalletModel)
        } else {
            models = [userWalletModel]
        }

        setSelectedUserWalletId(userWalletModel.userWalletId, unlockIfNeeded: true, reason: .inserted)
    }

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let userWalletModel):
                    if !models.contains(where: { $0.userWalletId == userWalletModel.userWalletId }) {
                        save(userWalletModel)
                        completion(result)
                    } else {
                        completion(.error(UserWalletRepositoryError.duplicateWalletAdded))
                        return
                    }

                    setSelectedUserWalletId(userWalletModel.userWalletId, unlockIfNeeded: true, reason: .inserted)
                default:
                    completion(result)
                }
            }
            .store(in: &bag)
    }

    func save() {
        let serialized = models.compactMap { $0.userWallet }
        UserWalletRepositoryUtil().saveUserWallets(serialized)
    }

    // TODO: refactor
    func save(_ userWalletModel: UserWalletModel) {
        if let index = models.firstIndex(where: { $0.userWalletId == userWalletModel.userWalletId }) {
            models[index] = userWalletModel
        } else {
            models.append(userWalletModel)
            sendEvent(.inserted(userWalletId: userWalletModel.userWalletId))
        }

        if let userWalletIdSeed = userWalletModel.config.userWalletIdSeed {
            encryptionKeyStorage.add(userWalletModel.userWalletId, encryptionKey: UserWalletEncryptionKey(userWalletIdSeed: userWalletIdSeed))
            save()
        } else {
            AppLog.shared.debug("Failed to get encryption key for UserWallet")
        }

        sendEvent(.updated(userWalletId: userWalletModel.userWalletId))

        if selectedUserWalletId == nil {
            setSelectedUserWalletId(userWalletModel.userWalletId, unlockIfNeeded: true, reason: .inserted)
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

    func updateSelection() {
        initializeServicesForSelectedModel()
    }

    func logoutIfNeeded() {
        if models.contains(where: { !$0.isUserWalletLocked }) {
            return
        }

        lock(reason: .nothingToDisplay)
    }

    func setSelectedUserWalletId(_ userWalletId: UserWalletId, unlockIfNeeded: Bool, reason: UserWalletRepositorySelectionChangeReason) {
        guard selectedUserWalletId != userWalletId else { return }

        guard let model = models.first(where: {
            $0.userWalletId == userWalletId
        }) else {
            return
        }

        let updateSelection: (UserWalletModel) -> Void = { [weak self] userWalletModel in
            self?.selectedUserWalletId = userWalletModel.userWalletId
            AppSettings.shared.selectedUserWalletId = userWalletModel.userWalletId.value
            self?.initializeServicesForSelectedModel()
            self?.sendEvent(.selected(userWalletId: userWalletModel.userWalletId, reason: reason))
        }

        if !model.isUserWalletLocked || !unlockIfNeeded {
            updateSelection(model)
            return
        }

        unlock(with: .card(userWalletId: userWalletId)) { [weak self] result in
            guard
                let self,
                case .success = result,
                let selectedModel = models.first(where: { $0.userWalletId == userWalletId })
            else {
                return
            }

            updateSelection(selectedModel)
        }
    }

    func delete(_ userWalletId: UserWalletId, logoutIfNeeded shouldAutoLogout: Bool) {
        guard let userWallet = models.first(where: { $0.userWalletId == userWalletId })?.userWallet else {
            return
        }

        if selectedUserWalletId == userWalletId {
            resetServices()
        }

        let targetIndex: Int
        if let currentIndex = models.firstIndex(where: { $0.userWalletId == userWalletId }) {
            targetIndex = currentIndex > 0 ? (currentIndex - 1) : 0
        } else {
            targetIndex = 0
        }

        encryptionKeyByUserWalletId[userWalletId] = nil
        models.removeAll { $0.userWalletId == userWalletId }

        encryptionKeyStorage.delete(userWalletId)

        if AppSettings.shared.saveAccessCodes {
            do {
                let accessCodeRepository = AccessCodeRepository()
                try accessCodeRepository.deleteAccessCode(for: Array(userWallet.associatedCardIds))
            } catch {
                AppLog.shared.error(error)
            }
        }

        save()

        if !models.isEmpty {
            let newModel = models[targetIndex]
            setSelectedUserWalletId(newModel.userWalletId, unlockIfNeeded: false, reason: .deleted)
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
        analyticsContext.clearSession()

        sendEvent(.locked(reason: reason))
    }

    func clearNonSelectedUserWallets() {
        let selectedModel = selectedModel
        let otherUserWallets = models.filter { $0.userWalletId != selectedUserWalletId }

        clearUserWalletStorage()
        discardSensitiveData(except: selectedModel)

        sendEvent(.deleted(userWalletIds: otherUserWallets.map { $0.userWalletId }))
    }

    func initializeServices(for userWalletModel: UserWalletModel) {
        analyticsContext.setupContext(with: userWalletModel.analyticsContextData)
        tangemApiService.setAuthData(userWalletModel.tangemApiAuthData)
        walletConnectService.initialize(with: userWalletModel)
    }

    // we can initialize it right after scan for more accurate analytics
    func initializeAnalyticsContext(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let contextData = AnalyticsContextData(
            card: cardInfo.card,
            productType: config.productType,
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
        } else {
            models = []
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
                    self.loadModels()
                    self.initializeServicesForSelectedModel()

                    self.sendEvent(.biometryUnlocked)

                    if let selectedModel = self.selectedModel { // TODO: WTF?
                        let savedUserWallets = self.savedUserWallets(withSensitiveData: false)
                        if keys.count == savedUserWallets.count {
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
                    models = [userWalletModel]
                    selectedUserWalletId = userWalletModel.userWalletId
                    sendEvent(.replaced(userWalletId: userWalletModel.userWalletId))
                    completion(result)
                    return
                }

                guard let userWalletIdSeed = userWalletModel.config.userWalletIdSeed else {
                    completion(.error(TangemSdkError.cardError))
                    return
                }

                if let requiredUserWalletId, userWalletModel.userWalletId != requiredUserWalletId {
                    completion(.error(UserWalletRepositoryError.cardWithWrongUserWalletIdScanned))
                    return
                }

                let encryptionKey = UserWalletEncryptionKey(userWalletIdSeed: userWalletIdSeed)
                encryptionKeyByUserWalletId[userWalletModel.userWalletId] = encryptionKey
                // We have to refresh a key on every scan because we are unable to check presence of the key
                encryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: userWalletModel.userWalletId)

                if models.isEmpty {
                    loadModels()
                }

                if models.contains(where: { $0.userWalletId == userWalletModel.userWalletId }) {
                    // unlock current card
                    loadModel(for: userWalletModel.userWalletId)
                } else {
                    // add
                    save(userWalletModel)
                }

                // TODO: We have to create userWalletModel twice. First on scan and second - during restoring from a storage. Shoul be refactored.
                guard
                    let userWalletModel = models.first(where: { $0.userWalletId == userWalletModel.userWalletId })
                else {
                    return
                }

                setSelectedUserWalletId(userWalletModel.userWalletId, unlockIfNeeded: true, reason: .userSelected)
                initializeServicesForSelectedModel()

                sendEvent(.updated(userWalletId: userWalletModel.userWalletId))
                completion(.success(userWalletModel))
            }
            .store(in: &bag)
    }

    private func loadModels() {
        let savedUserWallets = savedUserWallets(withSensitiveData: true)

        models = savedUserWallets.map { userWalletStorageItem in
            if let userWallet = CommonUserWalletModel(userWallet: userWalletStorageItem) {
                return userWallet
            } else {
                return LockedUserWalletModel(with: userWalletStorageItem)
            }
        }
    }

    private func loadModel(for userWalletId: UserWalletId) {
        // find locked to replace
        guard let index = models.firstIndex(where: { $0.userWalletId == userWalletId }) else { return }

        guard let savedUserWallet = savedUserWallet(with: userWalletId),
              let userWalletModel = CommonUserWalletModel(userWallet: savedUserWallet) else {
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

    private func savedUserWallet(with userWalletId: UserWalletId) -> StoredUserWallet? {
        let keys = encryptionKeyByUserWalletId.filter { $0.key == userWalletId }
        let userWallets = UserWalletRepositoryUtil().savedUserWallets(encryptionKeyByUserWalletId: keys)
        return userWallets.first { $0.userWalletId == userWalletId.value }
    }
}

extension CommonUserWalletRepository {
    func initialize() {
        let savedSelectedUserWalletId = AppSettings.shared.selectedUserWalletId
        if !savedSelectedUserWalletId.isEmpty {
            selectedUserWalletId = UserWalletId(value: savedSelectedUserWalletId)
        }

        AppLog.shared.debug("CommonUserWalletRepository initialized")
    }

    func initialClean() {
        // Removing UserWallet-related data from Keychain
        AppLog.shared.debug("Clean CommonUserWalletRepository")
        clearUserWalletStorage()
    }
}

private extension UserWalletModel {
    var userWallet: StoredUserWallet? {
        (self as? UserWalletSerializable)?.serialize()
    }
}
