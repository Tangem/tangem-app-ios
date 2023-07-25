//
//  WalletConnectAction.swift
//  Tangem
//
//  Created by Andrew Son on 19/12/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectAction: String {
    case personalSign = "personal_sign"
    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    case bnbSign = "bnb_sign"
    case bnbTxConfirmation = "bnb_tx_confirmation"
    case signTypedData = "eth_signTypedData"
    case signTypedDataV4 = "eth_signTypedData_v4"
    case switchChain = "wallet_switchEthereumChain"

    var successMessage: String {
        switch self {
        case .personalSign, .signTypedData, .signTypedDataV4: return Localization.walletConnectMessageSigned
        case .signTransaction: return Localization.walletConnectTransactionSigned
        case .sendTransaction: return Localization.walletConnectTransactionSignedAndSend
        case .bnbSign: return Localization.walletConnectBnbTransactionSigned
        case .bnbTxConfirmation, .switchChain: return ""
        }
    }
}
