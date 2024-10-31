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
    case switchChain = "wallet_switchEthereumChain"

    // MARK: - ETH

    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    case signTypedData = "eth_signTypedData"
    case signTypedDataV4 = "eth_signTypedData_v4"

    // MARK: - BNB

    case bnbSign = "bnb_sign"
    case bnbTxConfirmation = "bnb_tx_confirmation"

    // MARK: - SOL

    case solanaSignTransaction = "solana_signTransaction"
    case solanaSignMessage = "solana_signMessage"
}
