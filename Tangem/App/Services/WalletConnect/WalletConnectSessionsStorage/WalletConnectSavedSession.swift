//
//  WalletConnectSavedSession.swift
//  Tangem
//
//  Created by Andrew Son on 13/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectSavedSession: Codable, Hashable, Identifiable {
    var id: Int { hashValue }
    let userWalletId: String
    let topic: String
    let sessionInfo: SessionInfo
}

extension WalletConnectSavedSession {
    struct SessionInfo: Codable, Hashable {
        let dAppInfo: DAppInfo
    }

    struct DAppInfo: Codable, Hashable {
        let name: String
        let description: String
        let url: String
        let iconLinks: [String]
    }
}
