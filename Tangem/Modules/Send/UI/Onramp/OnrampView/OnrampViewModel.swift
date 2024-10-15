//
//  OnrampViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnrampViewModel: ObservableObject, Identifiable {
    @Published var onrampAmountViewModel: OnrampAmountViewModel

    init(onrampAmountViewModel: OnrampAmountViewModel) {
        self.onrampAmountViewModel = onrampAmountViewModel
    }
}

// extension OnrampViewModel {
//    struct Settings {
//        let amount: OnrampAmountViewModel.Settings
//    }
// }
