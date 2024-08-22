//
//  MultipleRewardsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class MultipleRewardsViewModel: ObservableObject {

    // MARK: - ViewState
    
    @Published var validators: [ValidatorViewData] = []

    // MARK: - Dependencies

    private weak var coordinator: MultipleRewardsRoutable?

    init(
        coordinator: MultipleRewardsRoutable
    ) {
        self.coordinator = coordinator
    }
}
