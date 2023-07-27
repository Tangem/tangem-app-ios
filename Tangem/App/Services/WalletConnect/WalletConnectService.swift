//
//  WalletConnectService.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var newSessions: AsyncStream<[WalletConnectSavedSession]> { get async }

    func initialize(with infoProvider: WalletConnectUserWalletInfoProvider)
    func reset()
    func openSession(with uri: WalletConnectRequestURI)
    func disconnectSession(with id: Int) async
    func disconnectAllSessionsForUserWallet(with userWalletId: String)
}

private struct WalletConnectServicingKey: InjectionKey {
    static var currentValue: WalletConnectService = CommonWalletConnectService()
}

extension InjectedValues {
    var walletConnectService: WalletConnectService {
        get { Self[WalletConnectServicingKey.self] }
        set { Self[WalletConnectServicingKey.self] = newValue }
    }
}
