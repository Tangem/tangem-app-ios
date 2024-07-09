//
//  MarketsWalletSelectorProvider.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsWalletSelectorProvider: AnyObject {
    /// Published value selected UserWalletModel
    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> { get }

    /// ViewModels list for wallet selector screen
    var itemViewModels: [WalletSelectorItemViewModel] { get }
}
