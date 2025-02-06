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
    private(set) var customerWalletAddress: String = "0x3e24897ab2a19ca51536839fda818f8ea99cf96b"
    var activationOrder: VisaCardActivationOrder {
        .init(
            id: "f30bee47-21b6-4d07-9492-a5f2e0542875",
            customerId: "f89a0b9e-e5ae-4c34-b0cd-f335f5c2a9f3",
            customerWalletAddress: customerWalletAddress
        )
    }

    var isWalletAuthorizationTokenEnabled: Bool {
        activationRemoteState == .activated
    }

    private init() {}

    public func showMocksMenu(openSupportAction: @escaping () -> Void, presenter: VisaMockMenuPresenter) {
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
            UIAlertAction(
                title: "Select customer wallet address",
                style: .default
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.changeCustomerWalletAddress(presenter)
                }
            },
            UIAlertAction(
                title: "Open Support",
                style: .default,
                handler: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        openSupportAction()
                    }
                }
            ),
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
                self.changeActivationRemoteState(to: state)
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
                self.changeActivationRemoteState(to: .activated)
            },
            .init(title: "Disabled", style: .default) { _ in
                self.changeActivationRemoteState(to: .cardWalletSignatureRequired)
            },
        ]
        let actionSheet = buildActionSheet(
            title: "Change Wallet authorization token availability",
            message: "When set to enabled - mocked API will return remote state `.activated`\nWhen set to disabled - mocked API will return remote state `.cardWalletSignatureRequired`",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeCustomerWalletAddress(_ presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = [
        ]
        let alertController = UIAlertController(
            title: "Enter new customer wallet address",
            message: "Current Customer Wallet Address is: \(customerWalletAddress)",
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.placeholder = "Customer wallet address..."
            textField.keyboardType = .default
        }

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            guard let textField = alertController.textFields?.first,
                  let text = textField.text, !text.isEmpty else {
                return
            }

            self.customerWalletAddress = text
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }

        // Add actions to the alert controller
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        presenter.modalFromTop(alertController)
    }

    func changeActivationRemoteState(to newState: VisaCardActivationRemoteState) {
        activationRemoteState = newState
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

    func getWalletAuthorizationChallenge(cardId: String, walletAddress: String) async throws -> VisaAuthChallengeResponse {
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

// MARK: - VisaCardActivationStatusService

struct CardActivationStatusServiceMock: VisaCardActivationStatusService {
    func getCardActivationStatus(authorizationTokens: VisaAuthorizationTokens, cardId: String, cardPublicKey: String) async throws -> VisaCardActivationStatus {
        return .init(
            activationRemoteState: VisaMocksManager.instance.activationRemoteState,
            activationOrder: VisaMocksManager.instance.activationOrder
        )
    }
}

struct CardActivationTaskOrderProviderMock: CardActivationOrderProvider {
    func provideActivationOrderForSign(activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo {
        let generator = RandomBytesGenerator()
        return VisaCardAcceptanceOrderInfo(
            activationOrder: VisaMocksManager.instance.activationOrder,
            hashToSignByWallet: generator.generateBytes(length: 32)
        )
    }
}

// MARK: - ProductActivationService

struct ProductActivationServiceMock: ProductActivationService {
    func getVisaCardDeployAcceptance(activationOrderId: String, customerWalletAddress: String) async throws -> String {
        let generator = RandomBytesGenerator()
        return generator.generateBytes(length: 32).hexString
    }

    func sendSignedVisaCardDeployAcceptance(activationOrderId: String, cardWalletAddress: String, signedAcceptance: String, rootOtp: String, rootOtpCounter: Int) async throws {
        VisaMocksManager.instance.changeActivationRemoteState(to: .customerWalletSignatureRequired)
    }

    func getCustomerWalletDeployAcceptance(activationOrderId: String, cardWalletAddress: String) async throws -> String {
        let generator = RandomBytesGenerator()
        return generator.generateBytes(length: 32).hexString
    }

    func sendSignedCustomerWalletDeployAcceptance(activationOrderId: String, customerWalletAddress: String, deployAcceptanceSignature: String) async throws {
        VisaMocksManager.instance.changeActivationRemoteState(to: .paymentAccountDeploying)
    }

    func sendSelectedPINCodeToIssuer(activationOrderId: String, sessionKey: String, iv: String, encryptedPin: String) async throws {
        VisaMocksManager.instance.changeActivationRemoteState(to: .waitingForActivationFinishing)
    }
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
