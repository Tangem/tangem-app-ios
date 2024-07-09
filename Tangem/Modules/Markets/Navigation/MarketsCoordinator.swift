//
//  MarketsCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root Published

    @Published private(set) var rootViewModel: MarketsViewModel? = nil

    // MARK: - Coordinators

    @Published var tokenMarketsDetailsCoordinator: TokenMarketsDetailsCoordinator? = nil

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottonSheetViewModel: MarketsListOrderBottonSheetViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: MarketsCoordinator.Options) {
        rootViewModel = .init(searchTextPublisher: options.searchTextPublisher, coordinator: self)
    }

    func onBottomScrollableSheetStateChange(_ state: BottomScrollableSheetState) {
        if state.isBottom {
            rootViewModel?.onBottomDisappear()
        } else {
            rootViewModel?.onBottomAppear()
        }
    }
}

extension MarketsCoordinator {
    struct Options {
        let searchTextPublisher: AnyPublisher<String, Never>
    }
}

extension MarketsCoordinator: MarketsRoutable {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        marketsListOrderBottonSheetViewModel = .init(from: provider)
    }

    func openTokenMarketsDetails(for tokenInfo: MarketsTokenModel) {
        let tokenMarketsDetailsCoordinator = TokenMarketsDetailsCoordinator()
        tokenMarketsDetailsCoordinator.start(with: .init(info: tokenInfo))

        self.tokenMarketsDetailsCoordinator = tokenMarketsDetailsCoordinator
    }
}
