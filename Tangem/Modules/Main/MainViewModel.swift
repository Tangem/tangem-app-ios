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

final class MainViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - ViewState

    @Published var pages: [MainUserWalletPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false
    @Published var showingDeleteConfirmation = false
    @Published var showAddressCopiedToast = false

    @Published var unlockWalletBottomSheetViewModel: UnlockUserWalletBottomSheetViewModel?

    // MARK: - Dependencies

    private var mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    private weak var coordinator: MainRoutable?

    private var bag = Set<AnyCancellable>()
    private var isLoggingOut = false

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.coordinator = coordinator
        self.mainUserWalletPageBuilderFactory = mainUserWalletPageBuilderFactory

        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
            multiWalletContentDelegate: self
        )
        bind()
    }

    convenience init(
        selectedUserWalletId: UserWalletId,
        coordinator: MainRoutable,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.init(coordinator: coordinator, mainUserWalletPageBuilderFactory: mainUserWalletPageBuilderFactory)

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

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
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
    }

    func updateIsBackupAllowed() {
        // TODO: Will be added in IOS-4165
    }

    func didTapEditWallet() {
        // TODO: Analytics
//        Analytics.log(.buttonEditWalletTapped)

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
        // TODO:
//        Analytics.log(.buttonDeleteWalletTapped)

        showingDeleteConfirmation = true
    }

    func didConfirmWalletDeletion() {
        guard let userWalletModel = userWalletRepository.selectedModel else { return }

        userWalletRepository.delete(userWalletModel.userWallet, logoutIfNeeded: true)
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
    }

    private func recreatePages() {
        pages = mainUserWalletPageBuilderFactory.createPages(
            from: userWalletRepository.models,
            lockedUserWalletDelegate: self,
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

                self?.userWalletRepository.setSelectedUserWalletId(userWalletId.value, unlockIfNeeded: false, reason: .userSelected)
            }
            .store(in: &bag)

        userWalletRepository.eventProvider
            .sink { [weak self] event in
                switch event {
                case .locked:
                    self?.isLoggingOut = true
                case .scan:
                    // TODO: Do we need to place spinner into Navbar?..
                    break
                case .inserted:
                    // Useless event...
                    break
                case .updated(let userWalletModel):
                    self?.addNewPage(for: userWalletModel)
                case .deleted(let userWalletIds):
                    // This model is alive for enough time to receive the "deleted" event
                    // after the last model has been removed and the application has been logged out
                    if self?.isLoggingOut == true {
                        return
                    }
                    self?.removePages(with: userWalletIds)
                case .selected:
                    break
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
            let page = mainUserWalletPageBuilderFactory.createPage(for: userWalletModel, lockedUserWalletDelegate: self, multiWalletContentDelegate: self)
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
