//
//  TokenItemViewState+WalletModelState.swift
//  Tangem
//
//  Created by Andrew Son on 11/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension TokenItemViewState {
    init(walletModel: WalletModel) {
        switch walletModel.state {
        case .created:
            self = .notLoaded
        case .noAccount(let message, _):
            self = .noAccount(message: message)
        case .failed(let error):
            self = .networkError(error)
        case .noDerivation:
            self = .noDerivation
        case .loading:
            self = .loading
        case .idle:
            // respect walletModel.isLoading and walletModel.isSuccessfullyLoaded, just show "–"
            switch walletModel.stakingManagerState {
            case .loadingError, .availableToStake, .staked, .notEnabled, .temporaryUnavailable:
                self = .loaded
            case .loading:
                self = .loading
            }
        }
    }
}
