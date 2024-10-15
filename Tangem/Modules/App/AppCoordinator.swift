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
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.appLockController) private var appLockController: AppLockController

    // MARK: - Child coordinators

    /// Published property, used by UI. `SwiftUI.Binding` API requires it to be writable,
    /// but in fact this is a read-only binding since the UI never mutates it.
    @Published var marketsCoordinator: MarketsCoordinator?

    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil

    /// An ugly workaround due to navigation issues in SwiftUI on iOS 18 and above, see IOS-7990 for details.
    @Published private(set) var isOverlayContentContainerShown = false

    // MARK: - View State

    @Published private(set) var viewState: ViewState?
    @Published private(set) var lockViewVisible: Bool = false

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
            setupWelcome()
        case .auth:
            setupAuth()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.tryUnlockWithBiometry()
            }

        case .uncompletedBackup:
            setupUncompletedBackup()
        }
    }

    func sceneDidEnterBackground() {
        withTransaction(.withoutAnimations()) {
            mainBottomSheetUIManager.hide()
            lockViewVisible = true
        }
    }

    func sceneWillEnterForeground() {
        guard lockViewVisible else {
            return
        }

        if appLockController.isLocked {
            handleLock(reason: .loggetOut) { [weak self] in
                self?.tryUnlockWithBiometry()
            }
        } else {
            lockViewVisible = false
            mainBottomSheetUIManager.show()
        }
    }

    private func tryUnlockWithBiometry() {
        appLockController.unlockApp { [weak self] result in
            guard let self else { return }

            withAnimation(.easeOut(duration: 0.3)) { [weak self] in
                self?.lockViewVisible = false
            }

            switch result {
            case .openAuth:
                setupAuth()
            case .openMain(let model):
                openMain(with: model)
            case .openWelcome:
                setupWelcome()
            }
        }
    }

    private func setupWelcome() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.start()
        }

        let welcomeCoordinator = WelcomeCoordinator(dismissAction: dismissAction)
        welcomeCoordinator.start(with: .init(shouldScan: false))
        // withTransaction call fixes stories animation on scenario: welcome -> onboarding -> main -> welcome
        withTransaction(.withoutAnimations()) {
            viewState = .welcome(welcomeCoordinator)
        }
    }

    private func setupAuth() {
        let dismissAction: Action<AuthDismissOptions> = { [weak self] options in
            guard let self else { return }

            switch options {
            case .main(let model):
                openMain(with: model)
            case .onboarding(let input):
                openOnboarding(with: input)
            }
        }

        let authCoordinator = AuthCoordinator(dismissAction: dismissAction)
        authCoordinator.start(with: .init())

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
        guard marketsCoordinator == nil else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.marketsCoordinator = nil
        }

        let coordinator = MarketsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init())
        marketsCoordinator = coordinator
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                if case .locked(reason: .nothingToDisplay) = event {
                    self?.handleLock(reason: .nothingToDisplay) { [weak self] in
                        self?.setupWelcome()
                    }
                }
            }
            .store(in: &bag)

        mainBottomSheetUIManager
            .isShownPublisher
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.setupMainBottomSheetCoordinatorIfNeeded()
            }
            .store(in: &bag)

        mainBottomSheetUIManager
            .isShownPublisher
            .assign(to: \.isOverlayContentContainerShown, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func handleLock(reason: LockReason, completion: @escaping () -> Void) {
        let animated = reason.shouldAnimateLogout

        marketsCoordinator = nil
        mainBottomSheetUIManager.hide(shouldUpdateFooterSnapshot: false)

        closeAllSheetsIfNeeded(animated: animated) {
            if animated {
                completion()
            } else {
                UIApplication.performWithoutAnimations {
                    completion()
                }
            }
        }
    }

    private func closeAllSheetsIfNeeded(animated: Bool, completion: @escaping () -> Void = {}) {
        guard
            let topViewController = UIApplication.topViewController,
            topViewController.presentingViewController != nil
        else {
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
    enum Options {
        case `default`
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

// Navigation

extension AppCoordinator {
    func openOnboarding(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.pushedOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .main)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
    }

    func openMain(with userWalletModel: UserWalletModel) {
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(userWalletModel: userWalletModel)
        coordinator.start(with: options)
        viewState = .main(coordinator)
    }
}

// LockReason

private enum LockReason {
    case nothingToDisplay
    case loggetOut

    var shouldAnimateLogout: Bool {
        switch self {
        case .loggetOut:
            false
        case .nothingToDisplay:
            true
        }
    }
}
