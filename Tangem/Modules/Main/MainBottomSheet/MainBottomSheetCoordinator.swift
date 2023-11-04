//
//  MainBottomSheetCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 04.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MainBottomSheetCoordinator: CoordinatorObject {
    @Injected(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Private Properties

    private var bag: Set<AnyCancellable> = []

    // MARK: - Root Published

    @Published private(set) var mainBottomSheetViewModel: MainBottomSheetViewModel? = nil

    var isMainBottomSheetEnabled: Bool { FeatureProvider.isAvailable(.mainScreenBottomSheet) }

    // MARK: - Child Coordinators

    @Published var networkSelectorCoordinator: ManageTokensNetworkSelectorCoordinator? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        let mainBottomSheetViewModel = MainBottomSheetViewModel(coordinator: self)

        bottomSheetVisibility
            .isShown
            .map { $0 ? mainBottomSheetViewModel : nil }
            .assign(to: \.mainBottomSheetViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func start(with options: Options) {}
}

extension MainBottomSheetCoordinator {
    struct Options {}
}

extension MainBottomSheetCoordinator: ManageTokensRoutable {
    func openTokenSelector(coinId: String, with tokenItems: [TokenItem]) {
        let coordinator = ManageTokensNetworkSelectorCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(coinId: coinId, tokenItems: tokenItems))
        networkSelectorCoordinator = coordinator
    }
}
