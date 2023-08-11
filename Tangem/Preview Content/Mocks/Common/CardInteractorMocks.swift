//
//  CardInteractorMocks.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CardInitializerMock: CardInitializable {
    func initializeCard(mnemonic: Mnemonic?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
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

class CardResettableMock: CardResettable {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success(()))
        }
    }
}

class CardInteractorMock: CardResettable {
    func resetCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        CardResettableMock().resetCard(completion: completion)
    }
}
