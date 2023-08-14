//
//  DefaultTokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 11/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultTokenItemInfoProvider {
    private unowned let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: Int { walletModel.id }

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> {
        walletModel.walletDidChangePublisher
            .map { TokenItemViewState(walletModelState: $0) }
            .eraseToAnyPublisher()
    }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var hasPendingTransactions: Bool { walletModel.hasPendingTransactions }

    var balance: String { walletModel.balance }

    var fiatBalance: String { walletModel.fiatBalance }
}
