//
//  WalletConnectUIBuilder.swift
//  Tangem
//
//  Created by Andrew Son on 08/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk

enum WalletConnectEvent {
    case establishSession
    case sign
    case sendTx
    case error
    case success

    var withCancelButton: Bool {
        switch self {
        case .error, .success: return false
        default: return true
        }
    }
}

enum WalletConnectUIBuilder {
    static func makeAlert(
        for event: WalletConnectEvent,
        message: String,
        onAcceptAction: @escaping () -> Void = {},
        isAcceptEnabled: Bool = true,
        onReject: @escaping () -> Void = {},
        extraTitle: String? = nil,
        onExtra: @escaping () -> Void = {}
    ) -> UIAlertController {
        let vc = UIAlertController(title: "WalletConnect", message: message, preferredStyle: .alert)
        let buttonTitle: String

        switch event {
        case .establishSession:
            buttonTitle = Localization.commonStart
        case .sign:
            buttonTitle = Localization.commonSign
        case .sendTx:
            buttonTitle = Localization.commonSignAndSend
        case .error, .success:
            buttonTitle = Localization.commonOk
        }

        if event.withCancelButton {
            vc.addAction(UIAlertAction(title: Localization.commonReject, style: .cancel, handler: { _ in onReject() }))
        }

        if let extraTitle = extraTitle {
            vc.addAction(UIAlertAction(title: extraTitle, style: .default, handler: { _ in onExtra() }))
        }

        let acceptButton = UIAlertAction(title: buttonTitle, style: .default, handler: { _ in onAcceptAction() })
        acceptButton.isEnabled = isAcceptEnabled
        vc.addAction(acceptButton)
        return vc
    }

    static func makeErrorAlert(_ error: Error) -> UIAlertController {
        makeAlert(for: .error, message: error.localizedDescription)
    }

    static func makeChainsSheet(_ wallets: [Wallet], onAcceptAction: @escaping (Wallet) -> Void, onReject: @escaping () -> Void) -> UIAlertController {
        let vc = UIAlertController(title: "WalletConnect", message: Localization.walletConnectSelectNetwork, preferredStyle: .actionSheet)

        for wallet in wallets {
            let addressFormatter = AddressFormatter(address: wallet.address)
            let title = "\(wallet.blockchain.displayName) (\(addressFormatter.truncated()))"
            let action = UIAlertAction(title: title, style: .default, handler: { _ in onAcceptAction(wallet) })
            vc.addAction(action)
        }

        vc.addAction(UIAlertAction(title: Localization.commonReject, style: .cancel, handler: { _ in onReject() }))

        return vc
    }
}
