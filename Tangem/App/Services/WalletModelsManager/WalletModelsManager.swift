//
//  WalletModelsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//
import Combine

protocol WalletModelsManager {
    var walletModels: [WalletModel] { get }
    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> { get }

    func updateAll(silent: Bool, completion: @escaping () -> Void)
}
