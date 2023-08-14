//
//  FakeUserWalletRepository.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeUserWalletRepository: UserWalletRepository {
    var models: [UserWalletModel] = []

    var userWallets: [UserWallet] = []

    var selectedModel: CardViewModel?

    var selectedUserWalletId: Data?

    var isEmpty: Bool { models.isEmpty }

    var count: Int { models.count }

    var isLocked: Bool = false

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    init(models: [UserWalletModel] = FakeUserWalletModel.allFakeWalletModels) {
        self.models = models
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func setSelectedUserWalletId(_ userWalletId: Data?, reason: UserWalletRepositorySelectionChangeReason) {}

    func updateSelection() {}

    func logoutIfNeeded() {}

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func save(_ cardViewModel: CardViewModel) {}

    func contains(_ userWallet: UserWallet) -> Bool {
        return false
    }

    func save(_ userWallet: UserWallet) {}

    func delete(_ userWallet: UserWallet, logoutIfNeeded shouldAutoLogout: Bool) {}

    func clear() {}

    func initialize() {}

    func initializeServices(for cardModel: CardViewModel, cardInfo: CardInfo) {}
}
