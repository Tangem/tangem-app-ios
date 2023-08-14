//
//  MainViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedCardScanTracker

    // MARK: - ViewState

    @Published var pages: [MainUserWalletPageBuilder] = []
    @Published var selectedCardIndex = 0
    @Published var isHorizontalScrollDisabled = false
    @Published var errorAlert: AlertBinder?
    @Published var showTroubleshootingView: Bool = false

    // MARK: - Dependencies

    private let mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    private weak var coordinator: MainRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Initializers

    init(
        coordinator: MainRoutable,
        mainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory
    ) {
        self.coordinator = coordinator
        self.mainUserWalletPageBuilderFactory = mainUserWalletPageBuilderFactory

        pages = mainUserWalletPageBuilderFactory.createPages(from: userWalletRepository.models)
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

    func scanCardAction() {
        Analytics.beginLoggingCardScan(source: .main)
        if AppSettings.shared.saveUserWallets {
            scanCard()
        } else {
            coordinator?.close(newScan: true)
        }
    }

    func openDetails() {
        // TODO: Refactor navigation to UserWalletModel instead of CardViewModel
        guard let cardViewModel = userWalletRepository.models[selectedCardIndex] as? CardViewModel else {
            log("Failed to cast user wallet model to CardViewModel")
            return
        }

        coordinator?.openDetails(for: cardViewModel)
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
        }
    }

    func updateIsBackupAllowed() {
        // TODO: Will be added in IOS-4165
    }

    // MARK: - Scan card

    private func scanCard() {
        userWalletRepository.add { [weak self] result in
            guard let self, let result else {
                return
            }

            switch result {
            case .troubleshooting:
                showTroubleshootingView = true
            case .onboarding(let input):
                openOnboarding(with: input)
            case .error(let error):
                if let userWalletRepositoryError = error as? UserWalletRepositoryError {
                    errorAlert = userWalletRepositoryError.alertBinder
                } else {
                    errorAlert = error.alertBinder
                }
            case .success(_), .partial:
                // Will be handled through `updated` user wallet repo event
                break
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

        guard let newPage = mainUserWalletPageBuilderFactory.createPage(for: userWalletModel) else {
            return
        }

        let newPageIndex = pages.count
        pages.append(newPage)
        selectedCardIndex = newPageIndex
    }

    private func removePage(with userWalletIds: [Data]) {
        pages.removeAll { page in
            userWalletIds.contains(page.id.value)
        }
        selectedCardIndex = 0
    }

    // MARK: - Private functions

    private func bind() {
        $selectedCardIndex
            .sink { [weak self] newIndex in
                guard let userWalletId = self?.pages[newIndex].id else {
                    return
                }

                self?.userWalletRepository.setSelectedUserWalletId(userWalletId.value, reason: .userSelected)
            }
            .store(in: &bag)

        userWalletRepository.eventProvider
            .sink { [weak self] event in
                switch event {
                case .locked:
                    break
                case .scan:
                    // TODO: Do we need to place spinner into Navbar?..
                    break
                case .inserted:
                    // Useless event...
                    break
                case .updated(let userWalletModel):
                    self?.addNewPage(for: userWalletModel)
                case .deleted(let userWalletIds):
                    self?.removePage(with: userWalletIds)
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

extension MainViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboardingModal(with: input)
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()

        coordinator?.openMail(with: failedCardScanTracker, emailType: .failedToScanCard, recipient: EmailConfig.default.recipient)
    }
}
