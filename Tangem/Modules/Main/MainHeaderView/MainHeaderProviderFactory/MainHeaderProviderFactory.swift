//
//  MainHeaderProviderFactory.swift
//  Tangem
//
//  Created by Andrew Son on 15/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderProviderFactory {
    func makeHeaderBalanceProvider(for model: UserWalletModel) -> MainHeaderBalanceProvider
    func makeHeaderSubtitleProvider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider
}
