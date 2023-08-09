//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoadingTokenList: Bool = true
    @Published var sections: [MultiWalletTokenItemsSection] = []
    @Published var pendingDerivationsCount: Int = 0

    @Published var isScannerBusy = false

    private let userWalletModel: UserWalletModel

    // MARK: - Dependencies

    private unowned let coordinator: MultiWalletMainContentRoutable
    private var sectionsProvider: TokenListInfoProvider

    private var isUpdating = false
    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        coordinator: MultiWalletMainContentRoutable,
        sectionsProvider: TokenListInfoProvider
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        self.sectionsProvider = sectionsProvider

        bind()
        subscribeToTokenListUpdatesIfNeeded()
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        if isUpdating {
            return
        }

        isUpdating = true
        userWalletModel.userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.userWalletModel.walletModelsManager.updateAll(silent: true, completion: {
                self?.isUpdating = false
                completionHandler()
            })
        }
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.noticeScanYourCardTapped)
        isScannerBusy = true
        userWalletModel.userTokensManager.deriveEntriesWithoutDerivation { [weak self] in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
            }
        }
    }

    private func bind() {
        userWalletModel.userTokensManager.derivationManager?
            .pendingDerivationsCount
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.pendingDerivationsCount, on: self, ownership: .weak)
            .store(in: &bag)

        sectionsProvider.sectionsPublisher
            .map(convertToSections(_:))
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func subscribeToTokenListUpdatesIfNeeded() {
        if !userWalletModel.userTokenListManager.userTokens.isEmpty || userWalletModel.didPerformInitialTokenSync {
            isLoadingTokenList = false
            return
        }

        var tokenSyncSubscription: AnyCancellable?
        tokenSyncSubscription = userWalletModel.didPerformInitialTokenSyncPublisher
            .filter { $0 }
            .sink(receiveValue: { [weak self] _ in
                self?.isLoadingTokenList = false
                withExtendedLifetime(tokenSyncSubscription) {}
            })
    }

    private func convertToSections(_ sections: [TokenListSectionInfo]) -> [MultiWalletTokenItemsSection] {
        MultiWalletTokenItemsSectionFactory()
            .makeSections(from: sections, tapAction: tokenItemTapped(_:))
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId) {
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }) else {
            return
        }

        coordinator.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }
}
