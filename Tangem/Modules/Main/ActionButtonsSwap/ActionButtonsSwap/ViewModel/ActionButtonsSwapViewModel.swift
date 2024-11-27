//
//  ActionButtonsSwapViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation
import Combine

final class ActionButtonsSwapViewModel: ObservableObject {
    // MARK: Published property

    @Published var sourceToken: ActionButtonsTokenSelectorItem? {
        didSet {
            if sourceToken == nil {
                destinationTokenSelectorViewModel = nil
            }
        }
    }

    @Published var destinationToken: ActionButtonsTokenSelectorItem?
    @Published private(set) var swapPairsListState: SwapPairsListState = .loaded

    // MARK: Public property

    var tokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    > {
        destinationTokenSelectorViewModel ?? sourceSwapTokenSelectorViewModel
    }

    var isNotAvailablePairs: Bool {
        guard
            let destinationTokenSelectorViewModel,
            case .data(let availableModels, _) = destinationTokenSelectorViewModel.viewState,
            availableModels.isEmpty,
            destinationTokenSelectorViewModel.searchText.isEmpty
        else {
            return false
        }

        return true
    }

    var isSourceTokenSelected: Bool {
        sourceToken != nil
    }

    // MARK: Private property

    private weak var coordinator: ActionButtonsSwapRoutable?
    private var destinationTokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    >?

    private let expressRepository: ExpressRepository
    private let userWalletModel: UserWalletModel
    private let sourceSwapTokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    >

    init(
        coordinator: some ActionButtonsSwapRoutable,
        userWalletModel: some UserWalletModel,
        sourceSwapTokeSelectorViewModel: TokenSelectorViewModel<
            ActionButtonsTokenSelectorItem,
            ActionButtonsTokenSelectorItemBuilder
        >
    ) {
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
        sourceSwapTokenSelectorViewModel = sourceSwapTokeSelectorViewModel

        let expressAPIProviderFactory = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userId: userWalletModel.userWalletId.stringValue,
            logger: AppLog.shared
        )

        expressRepository = CommonExpressRepository(
            walletModelsManager: userWalletModel.walletModelsManager,
            expressAPIProvider: expressAPIProviderFactory
        )
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .close:
            coordinator?.dismiss()
        case .didTapToken(let token):
            Task { @MainActor in
                if sourceToken == nil {
                    sourceToken = token
                    await updatePairs(for: token, userWalletModel: userWalletModel)
                } else {
                    selectToToken(token)
                }
            }
        }
    }

    @MainActor
    func updatePairs(for token: ActionButtonsTokenSelectorItem, userWalletModel: UserWalletModel) async {
        swapPairsListState = .loading

        do {
            try await expressRepository.updatePairs(for: token.walletModel)

            destinationTokenSelectorViewModel = makeToSwapTokenSelectorViewModel(
                from: token,
                userWalletModel: userWalletModel,
                expressRepository: expressRepository
            )

            swapPairsListState = .loaded
        } catch {
            swapPairsListState = .error(input: makeErrorNotificationInput(from: token, and: userWalletModel))
        }
    }

    private func selectToToken(_ token: ActionButtonsTokenSelectorItem) {
        destinationToken = token

        guard let sourceToken, let destinationToken else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.coordinator?.openExpress(
                for: sourceToken.walletModel,
                and: destinationToken.walletModel,
                with: self.userWalletModel
            )
        }
    }
}

// MARK: Enums

extension ActionButtonsSwapViewModel {
    enum SwapPairsListState: Equatable {
        case error(input: NotificationViewInput)
        case loading
        case loaded
    }

    enum Action {
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}

// MARK: - Fabric methods

private extension ActionButtonsSwapViewModel {
    func makeErrorNotificationInput(
        from token: ActionButtonsTokenSelectorItem,
        and userWalletModel: some UserWalletModel
    ) -> NotificationViewInput {
        let refreshRequiredEvent: ExpressNotificationEvent = .refreshRequired(
            title: Localization.commonError,
            message: Localization.commonUnknownError
        )

        return .init(
            style: .withButtons([
                .init(
                    action: { _, _ in
                        Task {
                            await self.updatePairs(for: token, userWalletModel: userWalletModel)
                        }
                    },
                    actionType: .refresh,
                    isWithLoader: false
                ),
            ]),
            severity: .warning,
            settings: .init(event: refreshRequiredEvent, dismissAction: nil)
        )
    }

    func makeToSwapTokenSelectorViewModel(
        from token: ActionButtonsTokenSelectorItem,
        userWalletModel: UserWalletModel,
        expressRepository: some ExpressRepository
    ) -> TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    > {
        .init(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SwapTokenSelectorStrings(tokenName: token.name),
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            tokenSorter: SwapDestinationTokenAvailabilitySorter(
                sourceTokenWalletModel: token.walletModel,
                expressRepository: expressRepository
            )
        )
    }
}
