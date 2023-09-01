//
//  AppCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class AppCoordinator: CoordinatorObject {
    let dismissAction: Action<Void> = { _ in }
    let popToRootAction: Action<PopToRootOptions> = { _ in }

    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.walletConnectSessionsStorageInitializable) private var walletConnectSessionStorageInitializer: Initializable

    // MARK: - Child coordinators

    @Published var welcomeCoordinator: WelcomeCoordinator?
    @Published var uncompletedBackupCoordinator: UncompletedBackupCoordinator?
    @Published var authCoordinator: AuthCoordinator?

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init() {
        // We can't move it into ServicesManager because of locked keychain during preheating
        userWalletRepository.initialize()
        walletConnectSessionStorageInitializer.initialize()
        bind()
    }

    func start(with options: AppCoordinator.Options = .default) {
        let startupProcessor = StartupProcessor()
        let startupOption = startupProcessor.getStartupOption()

        switch startupOption {
        case .welcome:
            setupWelcome(with: options)
        case .auth:
            setupAuth(with: options)
        case .uncompletedBackup:
            setupUncompletedBackup()
        }
    }

    private func restart(with options: AppCoordinator.Options = .default) {
        welcomeCoordinator = nil
        authCoordinator = nil
        start(with: options)
    }

    private func setupWelcome(with options: AppCoordinator.Options) {
        let dismissAction = { [weak self] in
            self?.welcomeCoordinator = nil
            self?.start()
        }

        let popToRootAction: Action<PopToRootOptions> = { [weak self] options in
            self?.closeAllSheetsIfNeeded(animated: true) {
                self?.welcomeCoordinator = nil
                self?.start(with: .init(newScan: options.newScan))
            }
        }

        let shouldScan = options.newScan ?? false

        let coordinator = WelcomeCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(shouldScan: shouldScan))
        welcomeCoordinator = coordinator
    }

    private func setupAuth(with options: AppCoordinator.Options) {
        let dismissAction = { [weak self] in
            self?.authCoordinator = nil
            self?.start()
        }

        let popToRootAction: Action<PopToRootOptions> = { [weak self] options in
            self?.closeAllSheetsIfNeeded(animated: true) {
                self?.authCoordinator = nil
                self?.start(with: .init(newScan: options.newScan))
            }
        }

        let unlockOnStart = options.newScan ?? true

        let coordinator = AuthCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(unlockOnStart: unlockOnStart))
        authCoordinator = coordinator
    }

    private func setupUncompletedBackup() {
        let dismissAction = { [weak self] in
            self?.uncompletedBackupCoordinator = nil
            self?.start()
        }

        let coordinator = UncompletedBackupCoordinator(dismissAction: dismissAction)
        coordinator.start()
        uncompletedBackupCoordinator = coordinator
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                if case .locked(let reason) = event {
                    self?.handleLock(reason: reason)
                }
            }
            .store(in: &bag)
    }

    private func handleLock(reason: UserWalletRepositoryLockReason) {
        let animated: Bool
        let newScan: Bool

        switch reason {
        case .loggedOut:
            animated = false
            newScan = AppSettings.shared.saveUserWallets
        case .nothingToDisplay:
            animated = true
            newScan = false
        }

        let options = AppCoordinator.Options(newScan: newScan)

        closeAllSheetsIfNeeded(animated: animated) {
            if animated {
                self.restart(with: options)
            } else {
                UIApplication.performWithoutAnimations {
                    self.restart(with: options)
                }
            }
        }
    }

    private func closeAllSheetsIfNeeded(animated: Bool, completion: @escaping () -> Void = {}) {
        guard let topViewController = UIApplication.topViewController,
              topViewController.presentingViewController != nil else {
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        topViewController.dismiss(animated: animated) {
            self.closeAllSheetsIfNeeded(animated: animated, completion: completion)
        }
    }
}

extension AppCoordinator {
    struct Options {
        let newScan: Bool?

        static let `default`: Options = .init(newScan: false)
    }
}
