//
//  MainViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import SwiftUI

final class MainViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @InjectedWritable(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    // MARK: - ViewState

    @Published var pages: [MainUserWalletPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false
    @Published var showAddressCopiedToast = false
    @Published var actionSheet: ActionSheetBinder?

    @Published var unlockWalletBottomSheetViewModel: UnlockUserWalletBottomSheetViewModel?

    let swipeDiscoveryAnimationTrigger = CardsInfoPagerSwipeDiscoveryAnimationTrigger()

    var isMainBottomSheetEnabled: Bool { FeatureProvider.isAvailable(.mainScreenBottomSheet) }

    // MARK: - Dependencies

    private let mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    private let swipeDiscoveryHelper: WalletSwipeDiscoveryHelper
    private weak var coordinator: MainRoutable?

    // MARK: - Internal state

    private var pendingUserWalletIdsToUpdate: Set<Data> = []
    private var pendingUserWalletModelsToAdd: [UserWalletModel] = []
    private var shouldRecreatePagesAfterAddingPendingWalletModels = false

    private var isLoggingOut = false

    private var bag: Set<AnyCancellable> = []

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.coordinator = coordinator
        self.swipeDiscoveryHelper = swipeDiscoveryHelper
        self.mainUserWalletPageBuilderFactory = mainUserWalletPageBuilderFactory

        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            mainViewDelegate: self,
            multiWalletContentDelegate: self
        )
        bind()
    }

    convenience init(
        selectedUserWalletId: UserWalletId,
        coordinator: MainRoutable,
        swipeDiscoveryHelper: WalletSwipeDiscoveryHelper,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.init(
            coordinator: coordinator,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: mainUserWalletPageBuilderFactory
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

    func onViewAppear() {
        Analytics.log(.mainScreenOpened)

        bottomSheetVisibility.show()

        addPendingUserWalletModelsIfNeeded { [weak self] in
            self?.swipeDiscoveryHelper.scheduleSwipeDiscoveryIfNeeded()
        }
    }

    func onViewDisappear() {
        bottomSheetVisibility.hide()
        swipeDiscoveryHelper.cancelScheduledSwipeDiscovery()
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
            viewModel.onPullToRefresh(completionHandler: completion)
        case .multiWallet(_, _, let viewModel):
            viewModel.onPullToRefresh(completionHandler: completion)
        case .lockedWallet:
            completion()
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

        guard let userWallet = userWalletRepository.selectedModel?.userWallet else { return }

        let alert = AlertBuilder.makeAlertControllerWithTextField(
            title: Localization.userWalletListRenamePopupTitle,
            fieldPlaceholder: Localization.userWalletListRenamePopupPlaceholder,
            fieldText: userWallet.name
        ) { [weak self] newName in
            guard userWallet.name != newName else { return }

            var newUserWallet = userWallet
            newUserWallet.name = newName

            self?.userWalletRepository.save(newUserWallet)
        }

        AppPresenter.shared.show(alert)
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
        guard
            let userWalletId = userWalletRepository.selectedUserWalletId,
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.value == userWalletId })
        else {
            return
        }

        userWalletRepository.delete(userWalletModel.userWalletId, logoutIfNeeded: true)
    }

    // MARK: - User wallets pages management

    /// Marks the given user wallet as 'dirty' (needs to be updated).
    private func setNeedsUpdateUserWallet(_ userWallet: UserWallet) {
        pendingUserWalletIdsToUpdate.insert(userWallet.userWalletId)
    }

    /// Checks if the given user wallet is 'dirty' (needs to be updated).
    private func userWalletAwaitsPendingUpdate(_ userWallet: UserWallet) -> Bool {
        return pendingUserWalletIdsToUpdate.contains(userWallet.userWalletId)
    }

    /// Postpones the creation of a new page for a given user wallet model if its
    /// user wallet is marked for update. Otherwise, the new page is added immediately.
    private func processUpdatedUserWalletModel(_ userWalletModel: UserWalletModel) {
        if userWalletAwaitsPendingUpdate(userWalletModel.userWallet) {
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

            var processedUserWalletIds: Set<Data> = []
            for userWalletModel in userWalletModels {
                processedUserWalletIds.insert(userWalletModel.userWallet.userWalletId)
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

        guard
            let newPage = mainUserWalletPageBuilderFactory.createPage(
                for: userWalletModel,
                lockedUserWalletDelegate: self,
                mainViewDelegate: self,
                multiWalletContentDelegate: self
            )
        else {
            return
        }

        let newPageIndex = pages.count
        pages.append(newPage)
        selectedCardIndex = newPageIndex
    }

    private func removePages(with userWalletIds: [Data]) {
        pages.removeAll { page in
            userWalletIds.contains(page.id.value)
        }

        guard
            let newSelectedId = userWalletRepository.selectedUserWalletId,
            let index = pages.firstIndex(where: { $0.id.value == newSelectedId })
        else {
            return
        }

        selectedCardIndex = index
    }

    /// Postpones pages re-creation if a given user wallet is marked for update.
    /// Otherwise, re-creates pages immediately.
    private func recreatePagesIfNeeded(for userWallet: UserWallet) {
        if userWalletAwaitsPendingUpdate(userWallet) {
            shouldRecreatePagesAfterAddingPendingWalletModels = true
        } else {
            recreatePages()
        }
    }

    private func recreatePages() {
        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            mainViewDelegate: self,
            multiWalletContentDelegate: self
        )
    }

    // MARK: - Private functions

    private func bind() {
        $selectedCardIndex
            .dropFirst()
            .sink { [weak self] newIndex in
                guard let userWalletId = self?.pages[newIndex].id else {
                    return
                }

                Analytics.log(.walletOpened)
                self?.userWalletRepository.setSelectedUserWalletId(
                    userWalletId.value,
                    unlockIfNeeded: false,
                    reason: .userSelected
                )
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
                    // TODO: Do we need to place spinner into Navbar?..
                    break
                case .inserted(let userWallet):
                    setNeedsUpdateUserWallet(userWallet)
                case .updated(let userWalletModel):
                    processUpdatedUserWalletModel(userWalletModel)
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
                }
            }
            .store(in: &bag)
    }

    private func log(_ message: String) {
        AppLog.shared.debug("[Main V2] \(message)")
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
        guard
            let index = pages.firstIndex(where: { $0.id == userWalletModel.userWalletId }),
            let page = mainUserWalletPageBuilderFactory.createPage(
                for: userWalletModel,
                lockedUserWalletDelegate: self,
                mainViewDelegate: self,
                multiWalletContentDelegate: self
            )
        else {
            return
        }

        pages[index] = page
        unlockWalletBottomSheetViewModel = nil
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        unlockWalletBottomSheetViewModel = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.coordinator?.openMail(with: dataCollector, emailType: emailType, recipient: recipient)
        }
    }
}

extension MainViewModel: MultiWalletContentDelegate {
    func displayAddressCopiedToast() {
        showAddressCopiedToast = true
    }
}

extension MainViewModel: MainViewDelegate {
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
    }
}
