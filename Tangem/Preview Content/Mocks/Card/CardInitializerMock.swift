//
//  CardInitializerMock.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CardInitializerMock: CardInitializable {
    var shouldReset: Bool = false

    func initializeCard(mnemonic: Mnemonic?, passphrase: String?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let cardInfo = CardInfo(
                card: .init(card: .walletWithBackup),
                walletData: .none,
                name: "",
                artwork: .noArtwork,
                primaryCard: nil
            )
            completion(.success(cardInfo))
        }
    }
}
