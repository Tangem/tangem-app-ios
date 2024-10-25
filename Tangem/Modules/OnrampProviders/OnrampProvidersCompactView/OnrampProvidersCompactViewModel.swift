//
//  OnrampProvidersCompactViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampProvidersCompactViewData: Hashable {
    let iconURL: URL?
    let paymentMethodName: String
    let providerName: String
    let badge: Badge?
}

extension OnrampProvidersCompactViewData {
    enum Badge: Hashable {
        case bestRate
    }
}
