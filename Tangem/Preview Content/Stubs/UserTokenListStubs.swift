//
//  UserTokenListStubs.swift
//  Tangem
//
//  Created by Andrew Son on 10/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct UserTokenListStubs {
    private static var walletUserWalletListURL: URL {
        Bundle.main.url(forResource: "walletUserWalletList", withExtension: "json")!
    }

    static var walletUserWalletList: UserTokenList {
        decodeFromURL(walletUserWalletListURL)!
    }

    private static func decodeFromURL(_ url: URL) -> UserTokenList? {
        AppLogger.debug("Attempt to decode file at url: \(url)")
        let dataStr = try! String(contentsOf: url)
        let decoder = JSONDecoder.tangemSdkDecoder
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            AppLogger.debug(dataStr)
            AppLogger.debug("Data count: \(String(describing: dataStr.data(using: .utf8)?.count))")
            return try decoder.decode(UserTokenList.self, from: dataStr.data(using: .utf8)!)
        } catch {
            AppLogger.debug("Failed to decode card. Reason: \(error)")
        }
        return nil
    }
}
