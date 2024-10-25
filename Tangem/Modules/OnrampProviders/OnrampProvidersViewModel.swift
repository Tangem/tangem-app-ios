//
//  OnrampProvidersViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class OnrampProvidersViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private weak var coordinator: OnrampProvidersRoutable?

    init(
        coordinator: OnrampProvidersRoutable
    ) {
        self.coordinator = coordinator
    }
}
