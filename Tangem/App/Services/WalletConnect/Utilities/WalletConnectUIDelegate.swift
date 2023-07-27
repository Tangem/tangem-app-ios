//
//  WalletConnectUIDelegate.swift
//  Tangem
//
//  Created by Andrew Son on 14/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectUIRequest {
    let event: WalletConnectEvent
    let message: String
    var approveAction: () -> Void
    var rejectAction: (() -> Void)?
}

struct WalletConnectAsyncUIRequest<T> {
    let event: WalletConnectEvent
    let message: String
    var approveAction: () async throws -> T
    var rejectAction: () async throws -> T
}

protocol WalletConnectUIDelegate {
    func showScreen(with request: WalletConnectUIRequest)
    @MainActor
    func getResponseFromUser<Result>(with request: WalletConnectAsyncUIRequest<Result>) async -> (() async throws -> Result)
}

struct WalletConnectAlertUIDelegate: WalletConnectUIDelegate {
    private let appPresenter: AppPresenter = .shared

    func showScreen(with request: WalletConnectUIRequest) {
        let alert = WalletConnectUIBuilder.makeAlert(
            for: request.event,
            message: request.message,
            onAcceptAction: request.approveAction,
            onReject: request.rejectAction ?? {}
        )

        appPresenter.show(alert)
    }

    @MainActor
    func getResponseFromUser<Result>(with request: WalletConnectAsyncUIRequest<Result>) async -> (() async throws -> Result) {
        await withCheckedContinuation { continuation in
            let alert = WalletConnectUIBuilder.makeAlert(
                for: request.event,
                message: request.message,
                onAcceptAction: {
                    continuation.resume(returning: request.approveAction)
                },
                onReject: {
                    continuation.resume(returning: request.rejectAction)
                }
            )
            appPresenter.show(alert)
        }
    }
}
