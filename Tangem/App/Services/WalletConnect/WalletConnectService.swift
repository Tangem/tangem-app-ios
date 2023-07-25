//
//  WalletConnectService.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonWalletConnectService {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var v2Service: WalletConnectV2Service?
}

extension CommonWalletConnectService: WalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        v2Service?.canEstablishNewSessionPublisher.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher()
            .eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await v2Service?.newSessions ?? AsyncStream { $0.finish() }
        }
    }

    func initialize(with cardModel: CardViewModel) {
        guard cardModel.shouldShowWC else {
            return
        }

        // Note: If we are planning to write unit tests for each class this factory can be wrapped
        // with protocol and injected via initializer. But for now I think it'll be enough.
        v2Service = WalletConnectFactory().createWCService(for: cardModel)
        incomingActionManager.becomeFirstResponder(self)
    }

    func reset() {
        incomingActionManager.resignFirstResponder(self)
        v2Service = nil
    }

    func disconnectSession(with id: Int) async {
        await v2Service?.disconnectSession(with: id)
    }

    func canOpenSession(with uri: WalletConnectRequestURI) -> Bool {
        switch uri {
        case .v2:
            return v2Service != nil
        }
    }

    func openSession(with uri: WalletConnectRequestURI) {
        switch uri {
        case .v2(let v2URI):
            v2Service?.openSession(with: v2URI)
        }
    }
}

// MARK: - IncomingActionResponder

extension CommonWalletConnectService: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .walletConnect(let uri) = action, canOpenSession(with: uri) else {
            return false
        }

        openSession(with: uri)
        return true
    }
}
