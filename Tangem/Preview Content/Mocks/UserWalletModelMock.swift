//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

class UserWalletModelMock: UserWalletModel {
    var isMultiWallet: Bool { false }

    var userWalletId: UserWalletId { .init(with: Data()) }

    var walletModels: [WalletModel] { [] }

    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }

    var userWallet: UserWallet {
        UserWallet(userWalletId: Data(), name: "", card: .init(card: .card), associatedCardIds: [], walletData: .none, artwork: nil, isHDWalletAllowed: false)
    }

    var totalBalanceProvider: TotalBalanceProviding { TotalBalanceProviderMock() }

    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> { .just(output: []) }

    func getSavedEntries() -> [StorageEntry] { [] }

    func getEntriesWithoutDerivation() -> [StorageEntry] { [] }

    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> { .just(output: []) }

    func canManage(amountType: BlockchainSdk.Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool { false }

    func update(entries: [StorageEntry]) {}

    func append(entries: [StorageEntry]) {}

    func remove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) {}

    func initialUpdate() {}

    func updateWalletName(_ name: String) {}

    func updateWalletModels() {}

    func updateAndReloadWalletModels(silent: Bool, completion: @escaping () -> Void) {}
}
