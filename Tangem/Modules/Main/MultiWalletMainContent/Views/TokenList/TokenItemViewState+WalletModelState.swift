//
//  TokenItemViewState+WalletModelState.swift
//  Tangem
//
//  Created by Andrew Son on 11/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension TokenItemViewState {
    init(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created:
            self = .notLoaded
        case .idle:
            self = .loaded
        case .loading:
            self = .loading
        case .noAccount(let message):
            self = .noAccount(message: message)
        case .failed(let error):
            self = .networkError(error)
        case .noDerivation:
            self = .noDerivation
        }
    }
}
