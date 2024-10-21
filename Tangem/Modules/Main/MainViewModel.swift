//
//  MainViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import CombineExt

final class MainViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

    // MARK: - ViewState

    @Published var pages: [MainUserWalletPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false
    @Published var actionSheet: ActionSheetBinder?

    @Published var unlockWalletBottomSheetViewModel: UnlockUserWalletBottomSheetViewModel?

    let swipeDiscoveryAnimationTrigger = CardsInfoPagerSwipeDiscoveryAnimationTrigger()

    // MARK: - Dependencies

    private let swipeDiscoveryHelper: WalletSwipeDiscoveryHelper
    private let mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    private let pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    private weak var coordinator: MainRoutable?

    // MARK: - Internal state

    private var pendingUserWalletIdsToUpdate: Set<UserWalletId> = []
    private var pendingUserWalletModelsToAdd: [UserWalletModel] = []
    private var shouldRecreatePagesAfterAddingPendingWalletModels = false

    private var shouldDelayBottomSheetVisibility = true
    private var isLoggingOut = false

    private var bag: Set<AnyCancellable> = []

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory,
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.coordinator = coordinator
        self.swipeDiscoveryHelper = swipeDiscoveryHelper
        self.mainUserWalletPageBuilderFactory = mainUserWalletPageBuilderFactory
        self.pushNotificationsAvailabilityProvider = pushNotificationsAvailabilityProvider

        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self
        )

        assert(pages.count == userWalletRepository.models.count, "Number of pages must be equal to number of UserWalletModels")

        bind()
    }

    convenience init(
        selectedUserWalletId: UserWalletId,
        coordinator: MainRoutable,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory,
        pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProvider
    ) {
        self.init(
            coordinator: coordinator,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: mainUserWalletPageBuilderFactory,
            pushNotificationsAvailabilityProvider: pushNotificationsAvailabilityProvider
        )

        if let selectedIndex = pages.firstIndex(where: { $0.id == selectedUserWalletId }) {
            selectedCardIndex = selectedIndex
        }
    }

    // MARK: - Internal functions

    func openDetails() {
        let userWalletModel = userWalletRepository.models[selectedCardIndex]

        if userWalletModel.isUserWalletLocked {
            openUnlockUserWalletBottomSheet(for: userWalletModel)
            return
        }

        coordinator?.openDetails(for: userWalletModel)
    }

    /// Handles `SwiftUI.View.onAppear(perform:)`.
    func onViewAppear() {
        Analytics.log(.mainScreenOpened)

        addPendingUserWalletModelsIfNeeded { [weak self] in
            self?.swipeDiscoveryHelper.scheduleSwipeDiscoveryIfNeeded()
        }

        openPushNotificationsAuthorizationIfNeeded()
    }

    /// Handles `SwiftUI.View.onDisappear(perform:)`.
    func onViewDisappear() {
        swipeDiscoveryHelper.cancelScheduledSwipeDiscovery()
    }

    /// Handles `UIKit.UIViewController.viewDidAppear(_:)`.
    func onDidAppear() {
        // The application is already in a locked state, so no attempts to show bottom sheet should be made
        guard !isLoggingOut else {
            return
        }

        let uiManager = mainBottomSheetUIManager
        /// On a `cold start` (e.g., after launching the app or after coming back from the background in a `locked` state:
        /// in both cases a new VM is created), the bottom sheet should become visible with some delay to prevent it from
        /// being placed over the authorization screen.
        /// This is a workaround until IOS-7856 is implemented.
        if shouldDelayBottomSheetVisibility {
            shouldDelayBottomSheetVisibility = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.bottomSheetVisibilityColdStartDelay) {
                uiManager.show()
            }
        } else {
            uiManager.show()
        }
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        Analytics.log(.mainRefreshed)

        isHorizontalScrollDisabled = true
        let completion = { [weak self] in
            self?.isHorizontalScrollDisabled = false
            completionHandler()
        }
        let page = pages[selectedCardIndex]

        switch page {
        case .singleWallet(_, _, let viewModel):
            viewModel?.onPullToRefresh(completionHandler: completion)
        case .multiWallet(_, _, let viewModel):
            viewModel.onPullToRefresh(completionHandler: completion)
        case .lockedWallet:
            completion()
        case .visaWallet(_, _, let viewModel):
            viewModel.onPullToRefresh(completionHandler: completion)
        }
    }

    func onPageChange(dueTo reason: CardsInfoPageChangeReason) {
        guard reason == .byGesture else { return }

        Analytics.log(.mainScreenWalletChangedBySwipe)

        if !AppSettings.shared.userDidSwipeWalletsOnMainScreen {
            AppSettings.shared.userDidSwipeWalletsOnMainScreen = true
        }
    }

    func updateIsBackupAllowed() {
        // TODO: Will be added in IOS-4165
    }

    func didTapEditWallet() {
        Analytics.log(.buttonEditWalletTapped)

        if let alert = AlertBuilder.makeWalletRenamingAlert(userWalletRepository: userWalletRepository) {
            AppPresenter.shared.show(alert)
        }
    }

    func didTapDeleteWallet() {
        Analytics.log(.buttonDeleteWalletTapped)

        let sheet = ActionSheet(
            title: Text(Localization.userWalletListDeletePrompt),
            buttons: [
                .destructive(Text(Localization.commonDelete), action: weakify(self, forFunction: MainViewModel.didConfirmWalletDeletion)),
                .cancel(Text(Localization.commonCancel)),
            ]
        )
        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func didConfirmWalletDeletion() {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        userWalletRepository.delete(userWalletModel.userWalletId, logoutIfNeeded: true)
    }

    // MARK: - User wallets pages management

    /// Marks the given user wallet as 'dirty' (needs to be updated).
    private func setNeedsUpdateUserWallet(_ userWalletId: UserWalletId) {
        pendingUserWalletIdsToUpdate.insert(userWalletId)
    }

    /// Checks if the given user wallet is 'dirty' (needs to be updated).
    private func userWalletAwaitsPendingUpdate(_ userWalletId: UserWalletId) -> Bool {
        return pendingUserWalletIdsToUpdate.contains(userWalletId)
    }

    /// Postpones the creation of a new page for a given user wallet model if its
    /// user wallet is marked for update. Otherwise, the new page is added immediately.
    private func processUpdatedUserWallet(_ userWalletId: UserWalletId) {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        if userWalletAwaitsPendingUpdate(userWalletId) {
            pendingUserWalletModelsToAdd.append(userWalletModel)
        } else {
            addNewPage(for: userWalletModel)
        }
    }

    /// Adds new pages for pending user wallet models and performs the required clean-up
    /// of 'dirty' (need to be updated) user wallets.
    private func addPendingUserWalletModelsIfNeeded(completion: @escaping () -> Void) {
        if pendingUserWalletModelsToAdd.isEmpty {
            completion()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.pendingWalletsInsertionDelay) { [weak self] in
            defer { completion() }

            guard let self = self else { return }

            let userWalletModels = pendingUserWalletModelsToAdd
            pendingUserWalletModelsToAdd.removeAll()

            var processedUserWalletIds: Set<UserWalletId> = []
            for userWalletModel in userWalletModels {
                processedUserWalletIds.insert(userWalletModel.userWalletId)
                addNewPage(for: userWalletModel)
            }
            pendingUserWalletIdsToUpdate.subtract(processedUserWalletIds)

            if shouldRecreatePagesAfterAddingPendingWalletModels {
                shouldRecreatePagesAfterAddingPendingWalletModels = false
                recreatePages()
            }
        }
    }

    private func addNewPage(for userWalletModel: UserWalletModel) {
        // FIXME: Awaiting CommonUserWalletRepository event system refactoring
        // We need this check to prevent adding new pages after each
        // UserWalletModel update in `CommonUserWalletRepository`.
        // The problem itself not in `update` event from repository but
        // in `inserted` event, which is sending `UserWallet` instead of `UserWalletModel`
        if pages.contains(where: { $0.id == userWalletModel.userWalletId }) {
            return
        }

        let newPage = mainUserWalletPageBuilderFactory.createPage(
            for: userWalletModel,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self
        )

        let newPageIndex = pages.count
        pages.append(newPage)
        selectedCardIndex = newPageIndex
    }

    private func removePages(with userWalletIds: [UserWalletId]) {
        pages.removeAll { userWalletIds.contains($0.id) }

        guard
            let newSelectedId = userWalletRepository.selectedUserWalletId,
            let index = pages.firstIndex(where: { $0.id == newSelectedId })
        else {
            return
        }

        selectedCardIndex = index
    }

    /// Postpones pages re-creation if a given user wallet is marked for update.
    /// Otherwise, re-creates pages immediately.
    private func recreatePagesIfNeeded(for userWalletId: UserWalletId) {
        if userWalletAwaitsPendingUpdate(userWalletId) {
            shouldRecreatePagesAfterAddingPendingWalletModels = true
        } else {
            recreatePages()
        }
    }

    private func recreatePages() {
        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self
        )
    }

    // MARK: - Private functions

    private func bind() {
        $selectedCardIndex
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newIndex in
                guard let userWalletId = viewModel.pages[safe: newIndex]?.id else {
                    return
                }
                Analytics.log(.walletOpened)
                viewModel.userWalletRepository.setSelectedUserWalletId(
                    userWalletId,
                    reason: .userSelected
                )
            }
            .store(in: &bag)

        $selectedCardIndex
            .removeDuplicates()
            .prepend(-1) // A dummy value to trigger initial index change event
            .pairwise()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (previousCardIndex, currentCardIndex) = input
                viewModel.pages[safe: previousCardIndex]?.onPageDisappear()
                viewModel.pages[safe: currentCardIndex]?.onPageAppear()
            }
            .store(in: &bag)

        userWalletRepository.eventProvider
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }

                switch event {
                case .locked:
                    isLoggingOut = true
                case .scan:
                    break
                case .inserted(let userWalletId):
                    setNeedsUpdateUserWallet(userWalletId)
                case .updated(let userWalletId):
                    processUpdatedUserWallet(userWalletId)
                case .deleted(let userWalletIds):
                    // This model is alive for enough time to receive the "deleted" event
                    // after the last model has been removed and the application has been logged out
                    if isLoggingOut == true {
                        return
                    }
                    removePages(with: userWalletIds)
                    swipeDiscoveryHelper.reset()
                case .selected(let userWallet, let reason):
                    if reason == .inserted {
                        recreatePagesIfNeeded(for: userWallet)
                    }
                case .replaced(let userWallet):
                    recreatePagesIfNeeded(for: userWallet)
                case .biometryUnlocked:
                    break
                }
            }
            .store(in: &bag)

        // We need to check if some pages are missing body model. This can happen due to not loaded API list
        // In this case we need to recreate this pages after API list loaded and WalletModelsManager publishes list of models
        let indexesToRecreate: [Int] = pages.indexed().compactMap { $1.missingBodyModel ? $0 : nil }
        if !indexesToRecreate.isEmpty {
            let walletModelPublishers = indexesToRecreate.map { userWalletRepository.models[$0].walletModelsManager.walletModelsPublisher }
            walletModelPublishers.combineLatest()
                .combineLatest(apiListProvider.apiListPublisher)
                .receive(on: DispatchQueue.main)
                .withWeakCaptureOf(self)
                .sink { viewModel, tuple in
                    let (_, apiList) = tuple

                    if apiList.isEmpty {
                        return
                    }

                    var currentPages = viewModel.pages
                    for (index, page) in currentPages.indexed() {
                        // Double check that body model is still missing
                        guard
                            page.missingBodyModel,
                            index < viewModel.userWalletRepository.models.count
                        else {
                            continue
                        }

                        let userWalletModel = viewModel.userWalletRepository.models[index]
                        let updatedPage = viewModel.mainUserWalletPageBuilderFactory.createPage(
                            for: userWalletModel,
                            lockedUserWalletDelegate: viewModel,
                            singleWalletContentDelegate: viewModel,
                            multiWalletContentDelegate: viewModel
                        )

                        if updatedPage.missingBodyModel {
                            continue
                        }

                        currentPages[index] = updatedPage
                    }

                    viewModel.pages = currentPages
                }
                .store(in: &bag)
        }
    }

    private func log(_ message: String) {
        AppLog.shared.debug("[Main V2] \(message)")
    }

    private func openPushNotificationsAuthorizationIfNeeded() {
        if pushNotificationsAvailabilityProvider.isAvailable {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.pushNotificationAuthorizationRequestDelay) { [weak self] in
                self?.coordinator?.openPushNotificationsAuthorization()
            }
        }
    }
}

// MARK: - Navigation

extension MainViewModel: MainLockedUserWalletDelegate {
    func openUnlockUserWalletBottomSheet(for userWalletModel: UserWalletModel) {
        unlockWalletBottomSheetViewModel = .init(
            userWalletModel: userWalletModel,
            delegate: self
        )
    }
}

extension MainViewModel: UnlockUserWalletBottomSheetDelegate {
    func unlockedWithBiometry() {
        unlockWalletBottomSheetViewModel = nil
        recreatePages()
    }

    func userWalletUnlocked(_ userWalletModel: UserWalletModel) {
        guard let index = pages.firstIndex(where: { $0.id == userWalletModel.userWalletId }) else {
            return
        }

        let page = mainUserWalletPageBuilderFactory.createPage(
            for: userWalletModel,
            lockedUserWalletDelegate: self,
            singleWalletContentDelegate: self,
            multiWalletContentDelegate: self
        )
        pages[index] = page
        unlockWalletBottomSheetViewModel = nil
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        unlockWalletBottomSheetViewModel = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.feedbackRequestDelay) { [weak self] in
            self?.coordinator?.openMail(with: dataCollector, emailType: emailType, recipient: recipient)
        }
    }

    func openScanCardManual() {
        coordinator?.openScanCardManual()
    }
}

extension MainViewModel: MultiWalletMainContentDelegate {
    func displayAddressCopiedToast() {
        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }
}

extension MainViewModel: SingleWalletMainContentDelegate {
    func present(actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
    }
}

// MARK: - WalletSwipeDiscoveryHelperDelegate protocol conformance

extension MainViewModel: WalletSwipeDiscoveryHelperDelegate {
    func numberOfWallets(_ discoveryHelper: WalletSwipeDiscoveryHelper) -> Int {
        return pages.count
    }

    func userDidSwipeWallets(_ discoveryHelper: WalletSwipeDiscoveryHelper) -> Bool {
        return AppSettings.shared.userDidSwipeWalletsOnMainScreen
    }

    func helperDidTriggerSwipeDiscoveryAnimation(_ discoveryHelper: WalletSwipeDiscoveryHelper) {
        swipeDiscoveryAnimationTrigger.triggerDiscoveryAnimation()
    }
}

// MARK: - Constants

private extension MainViewModel {
    private enum Constants {
        /// A small delay for animated addition of newly inserted wallet(s) after the main view becomes visible.
        static let pendingWalletsInsertionDelay = 1.0
        static let feedbackRequestDelay = 0.7
        static let pushNotificationAuthorizationRequestDelay = 0.5
        // TODO: Andrey Fedorov - Get rid of this workaround (IOS-7856)
        static let bottomSheetVisibilityColdStartDelay = 0.5
    }
}
