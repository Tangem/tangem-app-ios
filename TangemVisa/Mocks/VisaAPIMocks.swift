//
//  VisaAPIMocks.swift
//  TangemVisa
//
//  Created by Andrew Son on 17/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemSdk

public protocol VisaMockMenuPresenter {
    func modalFromTop(_ vc: UIViewController)
}

public class VisaMocksManager {
    public static let instance = VisaMocksManager()

    private(set) var activationRemoteState: VisaCardActivationRemoteState = .cardWalletSignatureRequired

    var isWalletAuthorizationTokenEnabled: Bool {
        activationRemoteState == .activated
    }

    private init() {}

    public func showMocksMenu(presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = [
            UIAlertAction(
                title: "Card activation remote state",
                style: .default
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.changeCardActivationRemoteState(presenter)
                }
            },
            UIAlertAction(
                title: "Wallet Authorization Token availability",
                style: .default
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.changeWalletAuthorizationTokenAvailability(presenter)
                }
            },
        ]
        let actionSheet = buildActionSheet(
            title: "Select setting to toggle",
            message: "Actions will open additional action sheet with available settings",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeCardActivationRemoteState(_ presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = VisaCardActivationRemoteState.allCases.map { state in
            UIAlertAction(
                title: state.rawValue,
                style: .default
            ) { _ in
                self.activationRemoteState = state
            }
        }
        let actionSheet = buildActionSheet(
            title: "Card activation remote state",
            message: "Select new card activation state. It will be used in all mocked responses until changed again in this menu",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeWalletAuthorizationTokenAvailability(_ presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = [
            .init(title: "Enabled", style: .default) { _ in
                self.activationRemoteState = .activated
            },
            .init(title: "Disabled", style: .default) { _ in
                self.activationRemoteState = .cardWalletSignatureRequired
            },
        ]
        let actionSheet = buildActionSheet(
            title: "Change Wallet authorization token availability",
            message: "When set to enabled - mocked API will return remote state `.activated`\nWhen set to disabled - mocked API will return remote state `.cardWalletSignatureRequired`",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    private func buildActionSheet(title: String, message: String, actions: [UIAlertAction]) -> UIViewController {
        let vc = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )

        actions.forEach { vc.addAction($0) }

        vc.addAction(.init(title: "Cancel", style: .cancel))
        return vc
    }
}

struct AuthorizationServiceMock: VisaAuthorizationService, VisaAuthorizationTokenRefreshService {
    let authorizationTokens = VisaAuthorizationTokens(
        accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJjdXN0b21lcl9pZCI6IjQzMTI0ODkzMDItNDMyMTk4LWRiY2Q3ODk2NzhhZCJ9.XbwjH5e8_DcEdbakQ_gVwrfigqcUuuEpvPfS1HR-u9I",
        refreshToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJjdXN0b21lcl9pZCI6IjQzMTI0ODkzMDItNDMyMTk4LWRiY2Q3ODk2NzhhZCJ9.XbwjH5e8_DcEdbakQ_gVwrfigqcUuuEpvPfS1HR-u9I"
    )

    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse {
        return .init(
            nonce: RandomBytesGenerator().generateBytes(length: 16).hexString,
            sessionId: "e98b782c3a32329de53d78d16da7bf0c=e98b782c3a32329de53d78d16da7bf0c=="
        )
    }

    func getWalletAuthorizationChallenge(cardId: String, walletPublicKey: String) async throws -> VisaAuthChallengeResponse {
        return .init(
            nonce: RandomBytesGenerator().generateBytes(length: 32).hexString,
            sessionId: "098acd0987ba0af0787ff8abc90dcb12=098acd0987ba0af0787ff8abc90dcb12=="
        )
    }

    func getAccessTokensForCardAuth(signedChallenge: String, salt: String, sessionId: String) async throws -> VisaAuthorizationTokens {
        return authorizationTokens
    }

    func getAccessTokensForWalletAuth(signedChallenge: String, sessionId: String) async throws -> VisaAuthorizationTokens? {
        guard VisaMocksManager.instance.isWalletAuthorizationTokenEnabled else {
            return nil
        }

        return authorizationTokens
    }

    func refreshAccessToken(refreshToken: String) async throws -> VisaAuthorizationTokens {
        return try await getAccessTokensForCardAuth(signedChallenge: "", salt: "", sessionId: "")
    }
}

struct CardActivationRemoteStateServiceMock: VisaCardActivationRemoteStateService {
    func loadCardActivationRemoteState(authorizationTokens: VisaAuthorizationTokens) async throws -> VisaCardActivationRemoteState {
        return VisaMocksManager.instance.activationRemoteState
    }
}

struct CardActivationTaskOrderProviderMock: CardActivationOrderProvider {
    func provideActivationOrderForSign() async throws -> CardActivationOrder {
        let generator = RandomBytesGenerator()
        return CardActivationOrder(
            activationOrder: "tngm_activation_order",
            dataToSignByCard: generator.generateBytes(length: 16),
            dataToSignByWallet: generator.generateBytes(length: 32)
        )
    }

    func cancelOrderLoading() {}
}

private struct RandomBytesGenerator {
    func generateBytes(length: Int) -> Data {
        return Data((0 ..< length).map { _ -> UInt8 in
            UInt8(arc4random_uniform(255))
        })
    }
}

private extension VisaCardActivationRemoteState {
    static var allCases: [VisaCardActivationRemoteState] = [
        .cardWalletSignatureRequired,
        .customerWalletSignatureRequired,
        .paymentAccountDeploying,
        .waitingPinCode,
        .waitingForActivationFinishing,
        .activated,
        .blockedForActivation,
    ]
}
