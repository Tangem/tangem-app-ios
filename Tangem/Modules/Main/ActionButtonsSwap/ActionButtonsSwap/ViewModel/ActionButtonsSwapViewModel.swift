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

    @Published var sourceToken: ActionButtonsTokenSelectorItem?

    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var destinationToken: ActionButtonsTokenSelectorItem?

    @Published private(set) var tokenSelectorState: ActionButtonsTokenSelectorState = .initial

    // MARK: Public property

    var tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel {
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
    private var destinationTokenSelectorViewModel: ActionButtonsTokenSelectorViewModel?
    private var bag = Set<AnyCancellable>()

    private lazy var notificationManager: some NotificationManager = {
        let notificationManager = ActionButtonsSwapNotificationManager(
            statePublisher: $tokenSelectorState.eraseToAnyPublisher()
        )

        notificationManager.setupManager(with: self)

        return notificationManager
    }()

    private let expressRepository: ExpressRepository
    private let userWalletModel: UserWalletModel
    private let sourceSwapTokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    init(
        coordinator: some ActionButtonsSwapRoutable,
        userWalletModel: some UserWalletModel,
        sourceSwapTokeSelectorViewModel: ActionButtonsTokenSelectorViewModel
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

        bind()
    }

    func bind() {
        let makeNotificationPublisher = { [notificationManager] filter in
            notificationManager
                .notificationPublisher
                .removeDuplicates()
                .scan(([NotificationViewInput](), [NotificationViewInput]())) { prev, new in
                    (prev.1, new)
                }
                .filter(filter)
                .map(\.1)
        }

        // Publisher for showing new notifications with a delay to prevent unwanted animations
        makeNotificationPublisher { $1.count >= $0.count }
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        // Publisher for immediate updates when notifications are removed (e.g., from 2 to 0 or 1)
        // to fix 'jumping' animation bug
        makeNotificationPublisher { $1.count < $0.count }
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        $sourceToken
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, newValue in
                if newValue == nil {
                    viewModel.destinationTokenSelectorViewModel = nil
                    viewModel.tokenSelectorState = .initial
                }
            }
            .store(in: &bag)
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
                    selectDestinationToken(token)
                }
            }
        }
    }

    @MainActor
    func updatePairs(for token: ActionButtonsTokenSelectorItem, userWalletModel: UserWalletModel) async {
        tokenSelectorState = .loading

        do {
            try await expressRepository.updatePairs(for: token.walletModel)

            destinationTokenSelectorViewModel = makeToSwapTokenSelectorViewModel(
                from: token,
                userWalletModel: userWalletModel,
                expressRepository: expressRepository
            )

            tokenSelectorState = isNotAvailablePairs ? .noAvailablePairs : .loaded
        } catch {
            tokenSelectorState = .refreshRequired(
                title: Localization.commonError,
                message: Localization.commonUnknownError
            )
        }
    }

    private func selectDestinationToken(_ token: ActionButtonsTokenSelectorItem) {
        destinationToken = token
        tokenSelectorState = .readyToSwap

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
    enum ActionButtonsTokenSelectorState: Equatable {
        case initial
        case loading
        case loaded
        case readyToSwap
        case refreshRequired(title: String, message: String)
        case noAvailablePairs
    }

    enum Action {
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}

// MARK: - Notification

extension ActionButtonsSwapViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard
            let notification = notificationInputs.first(where: { $0.id == id }),
            let _ = notification.settings.event as? ActionButtonsNotificationEvent,
            let sourceToken
        else {
            return
        }

        switch action {
        case .refresh:
            Task {
                await self.updatePairs(for: sourceToken, userWalletModel: userWalletModel)
            }
        default:
            break
        }
    }
}

// MARK: - Fabric methods

private extension ActionButtonsSwapViewModel {
    func makeToSwapTokenSelectorViewModel(
        from token: ActionButtonsTokenSelectorItem,
        userWalletModel: UserWalletModel,
        expressRepository: some ExpressRepository
    ) -> ActionButtonsTokenSelectorViewModel {
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
