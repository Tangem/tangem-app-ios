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
import LocalAuthentication
import TangemSdk

class CommonUserWalletRepository: UserWalletRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.walletConnectService) private var walletConnectService: WalletConnectService
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable
    @Injected(\.analyticsContext) var analyticsContext: AnalyticsContext
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    var isLocked: Bool {
        let hasUnlockedModels = models.contains(where: { !$0.isUserWalletLocked })
        return !hasUnlockedModels
    }

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

    private var encryptionKeyByUserWalletId: [UserWalletId: UserWalletEncryptionKey] = [:]

    private let encryptionKeyStorage = UserWalletEncryptionKeyStorage()

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    private var bag: Set<AnyCancellable> = .init()

    init() {}

    deinit {
        AppLog.shared.debug("UserWalletRepository deinit")
    }

    private func scanPublisher(_ scanner: CardScanner) -> AnyPublisher<UserWalletRepositoryResult?, Never> {
        sendEvent(.scan(isScanning: true))

        return scanner.scanCardPublisher()
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

                cardInfo.name = UserWalletNameIndexationHelper.suggestedName(
                    config.cardName,
                    names: models.map(\.name)
                )

                let userWalletModel = CommonUserWalletModelFactory().makeModel(cardInfo: cardInfo)
                if let userWalletModel {
                    initializeServices(for: userWalletModel)
                }

                let factory = OnboardingInputFactory(
                    cardInfo: cardInfo,
                    userWalletModel: userWalletModel,
                    sdkFactory: config,
                    onboardingStepsBuilderFactory: config,
                    pushNotificationsInteractor: pushNotificationsInteractor
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
                sendEvent(.scan(isScanning: false))

                switch error.toTangemSdkError() {
                case .cardVerificationFailed:
                    return Just(UserWalletRepositoryResult.error(error))
                default:
                    failedCardScanTracker.recordFailure()
                    if failedCardScanTracker.shouldDisplayAlert {
                        return Just(UserWalletRepositoryResult.troubleshooting)
                    }

                    return Just(nil)
                }
            }
            .handleEvents(receiveCompletion: { _ in
                withExtendedLifetime(scanner) {}
            })
            .eraseToAnyPublisher()
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        unlockInternal(with: method) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let model), .partial(let model, _):
                let walletHasBackup = Analytics.ParameterValue.affirmativeOrNegative(for: model.hasBackupCards)

                Analytics.log(event: .signedIn, params: [
                    .signInType: method.analyticsValue.rawValue,
                    .walletsCount: "\(models.count)",
                    .walletHasBackup: walletHasBackup.rawValue,
                ])
            default:
                break
            }

            completion(result)
        }
    }

    func addOrScan(scanner: CardScanner, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        if AppSettings.shared.saveUserWallets {
            add(scanner: scanner, completion)
        } else {
            unlockWithCard(scanner: scanner, nil, completion: completion)
        }
    }

    private func updateAssociatedCard(for cardInfo: CardInfo) {
        guard let userWalletId = UserWalletIdFactory().userWalletId(from: cardInfo),
              let existing = models.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        existing.addAssociatedCard(cardInfo.card.cardId)
        save()
    }

    func add(_ userWalletModel: UserWalletModel) {
        if AppSettings.shared.saveUserWallets {
            save(userWalletModel)
        } else {
            models = [userWalletModel]
        }

        setSelectedUserWalletId(userWalletModel.userWalletId, reason: .inserted)
    }

    private func add(scanner: CardScanner, _ completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher(scanner)
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

                    setSelectedUserWalletId(userWalletModel.userWalletId, reason: .inserted)
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
            setSelectedUserWalletId(userWalletModel.userWalletId, reason: .inserted)
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

    func lock() {
        guard !isLocked else {
            return
        }

        lockInternal()
    }

    func setSelectedUserWalletId(_ userWalletId: UserWalletId, reason: UserWalletRepositorySelectionChangeReason) {
        guard selectedUserWalletId != userWalletId,
              let model = models.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        selectedUserWalletId = model.userWalletId
        AppSettings.shared.selectedUserWalletId = model.userWalletId.value
        initializeServicesForSelectedModel()
        sendEvent(.selected(userWalletId: model.userWalletId, reason: reason))
    }

    func delete(_ userWalletId: UserWalletId) {
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
        try? visaRefreshTokenRepository.deleteToken(cardId: userWallet.card.cardId)

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
            setSelectedUserWalletId(newModel.userWalletId, reason: .deleted)
        }

        walletConnectService.disconnectAllSessionsForUserWallet(with: userWalletId.stringValue)
        sendEvent(.deleted(userWalletIds: [userWalletId]))

        if !models.contains(where: { !$0.isUserWalletLocked }) {
            lockInternal()
        }
    }

    private func lockInternal() {
        discardSensitiveData()
        resetServices()
        analyticsContext.clearSession()
        sendEvent(.locked)
    }

    private func unlockInternal(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        switch method {
        case .biometry:
            unlockWithBiometry(completion: completion)
        case .card(let userWalletId, let scanner):
            unlockWithCard(scanner: scanner, userWalletId, completion: completion)
        }
    }

    func clearNonSelectedUserWallets() {
        let selectedModel = selectedModel
        let otherUserWallets = models.filter { $0.userWalletId != selectedUserWalletId }

        clearUserWalletStorage()
        clearVisaRefreshTokenRepository(except: selectedModel)
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
        let userWalletId = UserWalletIdFactory().userWalletId(config: config)
        let contextData = AnalyticsContextData(
            card: cardInfo.card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: userWalletId
        )

        analyticsContext.setupContext(with: contextData)
    }

    private func clearUserWalletStorage() {
        let userWalletRepositoryUtil = UserWalletRepositoryUtil()
        userWalletRepositoryUtil.saveUserWallets([])
        userWalletRepositoryUtil.removePublicDataEncryptionKey()

        encryptionKeyStorage.clear()
    }

    private func clearVisaRefreshTokenRepository(except userWalletModelToKeep: UserWalletModel? = nil) {
        if let userWalletModelToKeep, let cardId = userWalletModelToKeep.userWallet?.card.cardId {
            visaRefreshTokenRepository.clear(cardIdTokenToKeep: cardId)
        } else {
            visaRefreshTokenRepository.clear()
        }
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
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { [weak self] unlockResult in
            guard let self else { return }

            switch unlockResult {
            case .failure(let error):
                completion(.error(error))
            case .success(let context):
                unlockStoragesWithBiometryContext(context, completion: completion)
            }
        }
    }

    private func unlockStoragesWithBiometryContext(
        _ context: LAContext,
        completion: @escaping (UserWalletRepositoryResult?) -> Void
    ) {
        visaRefreshTokenRepository.fetch(using: context)

        DispatchQueue.main.async {
            do {
                let keys = try self.encryptionKeyStorage.fetch(context: context)

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
            } catch {
                AppLog.shared.error(error)
                completion(.error(error))
            }
        }
    }

    private func unlockWithCard(scanner: CardScanner, _ requiredUserWalletId: UserWalletId?, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        scanPublisher(scanner)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else {
                    completion(result)
                    return
                }

                // Scan new card via welcome screen with locked repository.
                if case .onboarding = result, models.isEmpty, AppSettings.shared.saveUserWallets {
                    loadModels()
                    completion(result)
                    return
                }

                guard case .success(let userWalletModel) = result else {
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

                setSelectedUserWalletId(userWalletModel.userWalletId, reason: .userSelected)
                initializeServicesForSelectedModel()

                sendEvent(.updated(userWalletId: userWalletModel.userWalletId))
                completion(.success(userWalletModel))
            }
            .store(in: &bag)
    }

    private func loadModels() {
        var savedUserWallets = savedUserWallets(withSensitiveData: true)
        migrateNamesIfNeeded(&savedUserWallets)

        models = savedUserWallets.map { userWalletStorageItem in
            if let userWallet = CommonUserWalletModelFactory().makeModel(userWallet: userWalletStorageItem) {
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
              let userWalletModel = CommonUserWalletModelFactory().makeModel(userWallet: savedUserWallet) else {
            return
        }

        models[index] = userWalletModel
    }

    private func initializeServicesForSelectedModel() {
        resetServices()

        guard let selectedModel else { return }

        initializeServices(for: selectedModel)
    }

    private func migrateNamesIfNeeded(_ wallets: inout [StoredUserWallet]) {
        guard !AppSettings.shared.didMigrateUserWalletNames else {
            return
        }

        if let migratedWallets = UserWalletNameIndexationHelper.migratedWallets(wallets) {
            UserWalletRepositoryUtil().saveUserWallets(migratedWallets)
            wallets = migratedWallets
        }

        AppSettings.shared.didMigrateUserWalletNames = true
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
