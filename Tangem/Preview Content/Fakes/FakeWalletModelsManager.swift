//
//  FakeWalletModelsManager.swift
//  Tangem
//
//  Created by Andrew Son on 01/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeWalletModelsManager: WalletModelsManager {
    var walletModels: [WalletModel] {
        walletModelsSubject.value
    }

    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> {
        walletModelsSubject
            .delay(for: 5, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private let walletModelsSubject: CurrentValueSubject<[WalletModel], Never>
    private var updateAllSubscription: AnyCancellable?

    init(walletManagers: [FakeWalletManager]) {
        walletModelsSubject = .init(walletManagers.flatMap { $0.walletModels })
    }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        let publishers = walletModels.map {
            $0.update(silent: silent)
        }

        updateAllSubscription = Publishers
            .MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .receive(on: RunLoop.main)
            .receiveCompletion { _ in
                completion()
            }
    }
}
