//
//  UserWalletRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletRepository: Initializable {
    var models: [UserWalletModel] { get }
    var userWallets: [UserWallet] { get }
    var selectedModel: CardViewModel? { get }
    var selectedUserWalletId: Data? { get }
    var isEmpty: Bool { get }
    var count: Int { get }
    var isLocked: Bool { get }
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { get }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void)
    func setSelectedUserWalletId(_ userWalletId: Data?, unlockIfNeeded: Bool, reason: UserWalletRepositorySelectionChangeReason)
    func updateSelection()
    func logoutIfNeeded()

    func add(_ userWalletModel: UserWalletModel)
    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void)
    // use this method for saving. TODO: refactor
    func save(_ cardViewModel: UserWalletModel)
    func contains(_ userWallet: UserWallet) -> Bool
    // use this method for updating. TODO: refactor
    func save(_ userWallet: UserWallet)
    func delete(_ userWallet: UserWallet, logoutIfNeeded shouldAutoLogout: Bool)
    func clearNonSelectedUserWallets()
    func initializeServices(for cardModel: CardViewModel, cardInfo: CardInfo)
}

extension UserWalletRepository {
    /// Selecting UserWallet with specified Id and unlocking it if needed
    func setSelectedUserWalletId(_ userWalletId: Data?, reason: UserWalletRepositorySelectionChangeReason) {
        setSelectedUserWalletId(userWalletId, unlockIfNeeded: true, reason: reason)
    }
}

private struct UserWalletRepositoryKey: InjectionKey {
    static var currentValue: UserWalletRepository = CommonUserWalletRepository()
}

extension InjectedValues {
    var userWalletRepository: UserWalletRepository {
        get { Self[UserWalletRepositoryKey.self] }
        set { Self[UserWalletRepositoryKey.self] = newValue }
    }
}

enum UserWalletRepositoryResult {
    case success(CardViewModel)
    case onboarding(OnboardingInput)
    case troubleshooting
    case error(Error)
    case partial(CardViewModel, Error)

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
}

enum UserWalletRepositoryEvent {
    case locked(reason: UserWalletRepositoryLockReason)
    case scan(isScanning: Bool)
    case inserted(userWallet: UserWallet)
    case updated(userWalletModel: UserWalletModel)
    case deleted(userWalletIds: [Data])
    case selected(userWallet: UserWallet, reason: UserWalletRepositorySelectionChangeReason)
}

enum UserWalletRepositorySelectionChangeReason {
    case userSelected
    case inserted
    case deleted
}

enum UserWalletRepositoryLockReason {
    case loggedOut
    case nothingToDisplay
}

enum UserWalletRepositoryUnlockMethod {
    case biometry
    case card(userWallet: UserWallet?)
}

enum UserWalletRepositoryError: String, Error, LocalizedError, BindableError {
    case duplicateWalletAdded
    case biometricsChanged
    case cardWithWrongUserWalletIdScanned

    var errorDescription: String? {
        rawValue
    }

    var alertBinder: AlertBinder {
        switch self {
        case .duplicateWalletAdded:
            return .init(title: "", message: Localization.userWalletListErrorWalletAlreadySaved)
        case .biometricsChanged:
            return .init(title: Localization.commonAttention, message: Localization.keyInvalidatedWarningDescription)
        case .cardWithWrongUserWalletIdScanned:
            return .init(title: Localization.commonWarning, message: Localization.errorWrongWalletTapped)
        }
    }
}
