//
//  InformationHiddenBalancesViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

// TODO: Integration in https://tangem.atlassian.net/browse/IOS-4782
final class InformationHiddenBalancesViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: InformationHiddenBalancesRoutable

    init(
        coordinator: InformationHiddenBalancesRoutable
    ) {
        self.coordinator = coordinator
    }

    func userDidRequestCloseView() {
        coordinator.closeInformationHiddenBalances()
    }

    func userDidRequestDoNotShowAgain() {
        coordinator.closeInformationHiddenBalances()
    }
}
