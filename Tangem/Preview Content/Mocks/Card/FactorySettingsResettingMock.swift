//
//  FactorySettingsResettingMock.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class FactorySettingsResettingMock: FactorySettingsResetting {
    func resetCard(headerMessage: String?, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success(()))
        }
    }
}
