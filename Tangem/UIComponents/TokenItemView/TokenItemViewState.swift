//
//  TokenItemViewState.swift
//  Tangem
//
//  Created by Andrew Son on 08/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemViewState {
    case notLoaded
    case noDerivation
    case loading
    case loaded
    case noAccount(message: String)
    case networkError(Error)

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
        case .loaded:
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
