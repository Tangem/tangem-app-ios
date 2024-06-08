//
//  WalletConnectRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectRowViewModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let action: () -> Void

    init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}
