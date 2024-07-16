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

    @Published var marketsCoordinator: MarketsCoordinator?
    @Published var shouldDismiss: Bool = false

    // MARK: - Child view models

    // Published property, used by UI
    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel?

    // Non-published property, used to preserve the state of the `MainBottomSheetHeaderViewModel`
    // instance between show-hide cycles
    private lazy var __headerViewModel = MainBottomSheetHeaderViewModel()

    @Published private(set) var overlayViewModel: MainBottomSheetOverlayViewModel?

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

    func start(with options: Void = ()) {
        setupManageTokens()
    }

    func onBottomScrollableSheetStateChange(_ state: BottomScrollableSheetState) {
        __headerViewModel.onBottomScrollableSheetStateChange(state)
        marketsCoordinator?.onBottomScrollableSheetStateChange(state)
    }

    private func bind() {
        bottomSheetVisibility
            .isShownPublisher
            .withWeakCaptureOf(self)
            .map { coordinator, isShown in
                return isShown ? coordinator.__headerViewModel : nil
            }
            .assign(to: \.headerViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupManageTokens() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.shouldDismiss = true
        }

        let coordinator = MarketsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(searchTextPublisher: __headerViewModel.enteredSearchTextPublisher))
        marketsCoordinator = coordinator
    }
}
