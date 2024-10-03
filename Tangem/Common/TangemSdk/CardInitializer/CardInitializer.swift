//
//  CardInitializer.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol CardInitializer {
    var shouldReset: Bool { get set }
    func initializeCard(mnemonic: Mnemonic?, passphrase: String?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void)
}
