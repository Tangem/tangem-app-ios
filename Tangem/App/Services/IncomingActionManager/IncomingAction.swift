//
//  IncomingAction.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum IncomingAction: Equatable {
    case walletConnect(WalletConnectRequestURI)
    case start // Run scan or request biometrics
    case dismissSafari(URL)
}
