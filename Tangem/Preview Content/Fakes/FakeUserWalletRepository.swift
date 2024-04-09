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
    var selectedUserWalletId: UserWalletId?

    var hasSavedWallets: Bool { true }

    var models: [UserWalletModel] = []

    var selectedModel: UserWalletModel?

    var selectedIndexUserWalletModel: Int?

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    init(models: [UserWalletModel] = FakeUserWalletModel.allFakeWalletModels) {
        self.models = models
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod, completion: @escaping (UserWalletRepositoryResult?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard self.models.first != nil else {
                completion(.error("No models"))
                return
            }

            switch method {
            case .biometry:
                completion(.troubleshooting)
            case .card(let userWalletId):
                if let userWalletId, let userWalletModel = self.models.first(where: { $0.userWalletId == userWalletId }) {
                    completion(.success(userWalletModel))
                    return
                }

                completion(.error("Can't create card view model"))
            }
        }
    }

    func setSelectedUserWalletId(_ userWalletId: UserWalletId, unlockIfNeeded: Bool, reason: UserWalletRepositorySelectionChangeReason) {}

    func updateSelection() {}

    func logoutIfNeeded() {}

    func add(_ userWalletModel: UserWalletModel) {}

    func add(_ completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func addOrScan(completion: @escaping (UserWalletRepositoryResult?) -> Void) {}

    func delete(_ userWalletId: UserWalletId, logoutIfNeeded shouldAutoLogout: Bool) {}

    func clearNonSelectedUserWallets() {}

    func initialize() {}

    func initializeServices(for userWalletModel: UserWalletModel) {}

    func initialClean() {}

    func setSaving(_ enabled: Bool) {}

    func save() {}
}
