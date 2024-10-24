//
//  SeedPhraseManager.swift
//  Tangem
//
//  Created by Andrew Son on 10/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SeedPhraseManager {
    private(set) var mnemonics: [EntropyLength: Mnemonic] = [:]

    func generateSeedPhrase() throws {
        let shortMnemonic = try Mnemonic(with: .bits128, wordList: .en)
        mnemonics[.bits128] = shortMnemonic
        let longMnemonic = try Mnemonic(with: .bits256, wordList: .en)
        mnemonics[.bits256] = longMnemonic
    }
}
