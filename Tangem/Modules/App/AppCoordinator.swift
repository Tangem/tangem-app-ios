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
import CombineExt
import SwiftUI

class AppCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void> = { _ in }
    let popToRootAction: Action<PopToRootOptions> = { _ in }

    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.walletConnectSessionsStorageInitializable) private var walletConnectSessionStorageInitializer: Initializable
    @Injected(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    // MARK: - Child coordinators

    @Published private(set) var viewState: ViewState?

    @Published var mainBottomSheetCoordinator: MainBottomSheetCoordinator?

    // MARK: - View State

    @Published private(set) var isMainBottomSheetShown = false

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

        setupMainBottomSheetCoordinatorIfNeeded()
    }

    private func restart(with options: AppCoordinator.Options = .default) {
        start(with: options)
    }

    private func setupWelcome(with options: AppCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.start()
        }

        let popToRootAction: Action<PopToRootOptions> = { [weak self] options in
            self?.closeAllSheetsIfNeeded(animated: true) {
                self?.start(with: .init(newScan: options.newScan))
            }
        }

        let shouldScan = options.newScan ?? false

        let welcomeCoordinator = WelcomeCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        welcomeCoordinator.start(with: .init(shouldScan: shouldScan))
        // withTransaction call fixes stories animation on scenario: welcome -> onboarding -> main -> welcome
        withTransaction(.withoutAnimations()) {
            viewState = .welcome(welcomeCoordinator)
        }
    }

    private func setupAuth(with options: AppCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.start()
        }

        let popToRootAction: Action<PopToRootOptions> = { [weak self] options in
            self?.closeAllSheetsIfNeeded(animated: true) {
                self?.start(with: .init(newScan: options.newScan))
            }
        }

        let unlockOnStart = options.newScan ?? true

        let authCoordinator = AuthCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        authCoordinator.start(with: .init(unlockOnStart: unlockOnStart))

        viewState = .auth(authCoordinator)
    }

    private func setupUncompletedBackup() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.start()
        }

        let uncompleteBackupCoordinator = UncompletedBackupCoordinator(dismissAction: dismissAction)
        uncompleteBackupCoordinator.start()

        viewState = .uncompleteBackup(uncompleteBackupCoordinator)
    }

    /// - Note: The coordinator is set up only once and only when the feature toggle is enabled.
    private func setupMainBottomSheetCoordinatorIfNeeded() {
        guard
            FeatureProvider.isAvailable(.markets),
            mainBottomSheetCoordinator == nil
        else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.mainBottomSheetCoordinator = nil
        }

        let coordinator = MainBottomSheetCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start()
        mainBottomSheetCoordinator = coordinator
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

        bottomSheetVisibility
            .isShownPublisher
            .assign(to: \.isMainBottomSheetShown, on: self, ownership: .weak)
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
        mainBottomSheetCoordinator = nil

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

// MARK: - Options

extension AppCoordinator {
    struct Options {
        let newScan: Bool?

        static let `default`: Options = .init(newScan: false)
    }
}

// MARK: - ViewState

extension AppCoordinator {
    enum ViewState: Equatable {
        case welcome(WelcomeCoordinator)
        case uncompleteBackup(UncompletedBackupCoordinator)
        case auth(AuthCoordinator)
        case main(MainCoordinator)

        static func == (lhs: AppCoordinator.ViewState, rhs: AppCoordinator.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.welcome, .welcome), (.uncompleteBackup, .uncompleteBackup), (.auth, .auth), (.main, .main):
                return true
            default:
                return false
            }
        }
    }
}
