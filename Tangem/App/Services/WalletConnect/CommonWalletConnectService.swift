//
//  CommonWalletConnectService.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonWalletConnectService {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var v2Service: WalletConnectV2Service

    init() {
        v2Service = WalletConnectFactory().createWCService()
    }
}

extension CommonWalletConnectService: WalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        v2Service.canEstablishNewSessionPublisher.eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await v2Service.newSessions
        }
    }

    func initialize(with infoProvider: WalletConnectUserWalletInfoProvider) {
        v2Service.initialize(with: infoProvider)
        incomingActionManager.becomeFirstResponder(self)
    }

    func reset() {
        incomingActionManager.resignFirstResponder(self)
    }

    func openSession(with uri: WalletConnectRequestURI) {
        switch uri {
        case .v2(let v2URI):
            v2Service.openSession(with: v2URI)
        }
    }

    func disconnectSession(with id: Int) async {
        await v2Service.disconnectSession(with: id)
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        v2Service.disconnectAllSessionsForUserWallet(with: userWalletId)
    }
}

// MARK: - IncomingActionResponder

extension CommonWalletConnectService: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .walletConnect(let uri) = action else {
            return false
        }

        openSession(with: uri)
        return true
    }
}
