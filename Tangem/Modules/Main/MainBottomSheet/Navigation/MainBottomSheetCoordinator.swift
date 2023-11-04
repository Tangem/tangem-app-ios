//
//  MainBottomSheetCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 04.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

class MainBottomSheetCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    // MARK: - Child coordinators

    @Published var networkSelectorCoordinator: ManageTokensNetworkSelectorCoordinator? = nil

    // MARK: - Child view models

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel? = nil
    @Published private(set) var contentViewModel: MainBottomSheetContentViewModel? = nil

    // MARK: - Private Properties

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        bind()
    }

    func start(with options: Options = .init()) {
        // TODO: Andrey Fedorov - Add actual implementation
    }

    private func bind() {
        let headerViewModel = MainBottomSheetHeaderViewModel()
        let contentViewModel = MainBottomSheetContentViewModel(
            enteredSearchTextPublisher: headerViewModel.enteredSearchTextPublisher,
            coordinator: self
        )
        let bottomSheetVisibilityPublisher = bottomSheetVisibility
            .isShown
            .share(replay: 1)

        bottomSheetVisibilityPublisher
            .map { $0 ? headerViewModel : nil }
            .assign(to: \.headerViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        bottomSheetVisibilityPublisher
            .map { $0 ? contentViewModel : nil }
            .assign(to: \.contentViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension MainBottomSheetCoordinator {
    struct Options {}
}

extension MainBottomSheetCoordinator: MainBottomSheetContentRoutable {
    func openTokenSelector(coinId: String, with tokenItems: [TokenItem]) {
        let coordinator = ManageTokensNetworkSelectorCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(coinId: coinId, tokenItems: tokenItems))
        networkSelectorCoordinator = coordinator
    }
}
