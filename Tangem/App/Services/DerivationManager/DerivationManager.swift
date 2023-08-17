//
//  DerivationManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

protocol DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> { get }
    var pendingDerivationsCount: AnyPublisher<Int, Never> { get }

    func deriveKeys(cardInteractor: CardDerivable, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
}

// TODO: refactor keys storage to single source and remove this delegate
protocol DerivationManagerDelegate: AnyObject {
    func onDerived(_ response: DerivationResult)
}
