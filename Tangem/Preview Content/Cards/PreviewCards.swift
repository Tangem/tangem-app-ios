//
//  PreviewCards.swift
//  Tangem
//
//  Created by Andrew Son on 18/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

extension Card {
    private static var walletWithBackupUrl: URL {
        Bundle.main.url(forResource: "walletWithBackup", withExtension: "json")!
    }

    private static var walletV2URL: URL {
        Bundle.main.url(forResource: "walletV2", withExtension: "json")!
    }

    private static var twinURL: URL {
        Bundle.main.url(forResource: "twinCard", withExtension: "json")!
    }

    private static var xrpNoteURL: URL {
        Bundle.main.url(forResource: "xrpNote", withExtension: "json")!
    }

    static var walletWithBackup: Card {
        return decodeFromURL(walletWithBackupUrl)!
    }

    static var walletV2: Card {
        return decodeFromURL(walletV2URL)!
    }

    static var twin: Card {
        return decodeFromURL(twinURL)!
    }

    static var xrpNote: Card {
        return decodeFromURL(xrpNoteURL)!
    }

    private static func decodeFromURL(_ url: URL) -> Card? {
        print("Attempt to decode file at url: \(url)")
        let dataStr = try! String(contentsOf: url)
        let decoder = JSONDecoder.tangemSdkDecoder
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            print(dataStr)
            return try decoder.decode(Card.self, from: dataStr.data(using: .utf8)!)
        } catch {
            print("Failed to decode card. Reason: \(error)")
        }
        return nil
    }
}
