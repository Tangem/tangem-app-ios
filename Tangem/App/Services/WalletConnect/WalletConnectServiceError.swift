//
//  WalletConnectServiceError.swift
//  Tangem
//
//  Created by Andrew Son on 19/12/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectServiceError: LocalizedError {
    case failedToConnect
    case signFailed
    case cancelled
    case timeout
    case deallocated
    case failedToFindSigner
    case sessionNotFound
    case txNotFound
    case failedToBuildTx(code: TxErrorCodes)
    case other(Error)
    case noChainId
    case unsupportedNetwork
    case switchChainNotSupported
    case notValidCard
    case networkNotFound(name: String)
    case unsupportedDApp

    var shouldHandle: Bool {
        switch self {
        case .cancelled, .deallocated, .failedToFindSigner: return false
        default: return true
        }
    }

    var errorDescription: String? {
        switch self {
        case .timeout: return Localization.walletConnectErrorTimeout
        case .signFailed: return Localization.walletConnectErrorSingFailed
        case .failedToConnect: return Localization.walletConnectErrorFailedToConnect
        case .txNotFound: return Localization.walletConnectTxNotFound
        case .sessionNotFound: return Localization.walletConnectSessionNotFound
        case .failedToBuildTx(let code): return Localization.walletConnectFailedToBuildTx(code.rawValue)
        case .other(let error): return error.localizedDescription
        case .noChainId: return Localization.walletConnectServiceNoChainId
        case .unsupportedNetwork: return Localization.walletConnectScannerErrorUnsupportedNetwork
        case .notValidCard: return Localization.walletConnectScannerErrorNotValidCard
        case .networkNotFound(let name): return Localization.walletConnectNetworkNotFoundFormat(name)
        case .unsupportedDApp: return Localization.walletConnectErrorUnsupportedDapp
        default: return ""
        }
    }
}

extension WalletConnectServiceError {
    enum TxErrorCodes: String {
        case noWalletManager
        case wrongAddress
        case noValue
    }
}
