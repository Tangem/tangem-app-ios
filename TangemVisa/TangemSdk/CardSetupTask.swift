//
//  CardSetupTask.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardSetupResponse {}

final class CardSetupTask: CardSessionRunnable {
    private let targetCardId: String
    private let targetCardPublicKey: Data

    init(targetCardId: String, targetCardPublicKey: Data) {
        self.targetCardId = targetCardId
        self.targetCardPublicKey = targetCardPublicKey
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<CardSetupResponse>) {
        // TODO: IOS-8569
    }
}
