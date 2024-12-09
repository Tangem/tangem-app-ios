//
//  VisaOnboardingTangemWalletConfirmationViewModel.swift
//  TangemApp
//
//  Created by Andrew Son on 04.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemSdk
import BlockchainSdk
import TangemVisa

protocol VisaOnboardingTangemWalletApproveDelegate: AnyObject {
    func processSignedData(_ signedData: Data) async throws
    /// We need to show alert in parent view, otherwise it won't be shown
    @MainActor
    func showAlert(_ alert: AlertBinder) async
}

protocol VisaOnboardingTangemWalletApproveDataProvider: AnyObject {
    func loadDataToSign() async throws -> Data
}

final class VisaOnboardingTangemWalletConfirmationViewModel: ObservableObject {
    struct ApprovePair {
        let cardId: String
        let publicKey: Data
        let derivationPath: DerivationPath?
        let tangemSdk: TangemSdk
    }

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var isLoading: Bool = false

    private let targetWalletAddress: String
    private var approvePair: ApprovePair?

    private weak var delegate: VisaOnboardingTangemWalletApproveDelegate?
    private weak var dataProvider: VisaOnboardingTangemWalletApproveDataProvider?

    private var approveCancellableTask: AnyCancellable?

    init(
        targetWalletAddress: String,
        delegate: VisaOnboardingTangemWalletApproveDelegate,
        dataProvider: VisaOnboardingTangemWalletApproveDataProvider,
        approvePair: ApprovePair? = nil
    ) {
        self.approvePair = approvePair
        self.targetWalletAddress = targetWalletAddress
        self.delegate = delegate
        self.dataProvider = dataProvider
    }

    func approveAction() {
        guard approveCancellableTask == nil else {
            return
        }

        approveCancellableTask = Task { [weak self] in
            guard let self else { return }

            do {
                guard let dataToSign = try await dataProvider?.loadDataToSign() else {
                    approveCancellableTask = nil
                    return
                }

                try Task.checkCancellation()

                if let approvePair {
                    try await signDataWithTargetPair(approvePair, dataToSign: dataToSign)
                } else {
                    try await signData(dataToSign)
                }
            } catch {
                if !error.isCancellationError {
                    await delegate?.showAlert(error.alertBinder)
                }
            }

            approveCancellableTask = nil
        }.eraseToAnyCancellable()
    }
}

private extension VisaOnboardingTangemWalletConfirmationViewModel {
    func signData(_ dataToSign: Data) async throws {
        let task = VisaCustomerWalletApproveTask(targetAddress: targetWalletAddress, approveData: dataToSign)
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()
        let signResponse: SignHashResponse = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(with: task) { result in
                switch result {
                case .success(let hashResponse):
                    continuation.resume(returning: hashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        try await delegate?.processSignedData(signResponse.signature)
    }

    func signDataWithTargetPair(_ approvePair: ApprovePair, dataToSign: Data) async throws {
        let signHashTask = SignHashCommand(hash: dataToSign, walletPublicKey: approvePair.publicKey, derivationPath: approvePair.derivationPath)
        let signResponse: SignHashResponse = try await withCheckedThrowingContinuation { continuation in
            approvePair.tangemSdk.startSession(with: signHashTask, cardId: approvePair.cardId) { result in
                switch result {
                case .success(let hashResponse):
                    continuation.resume(returning: hashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        try await delegate?.processSignedData(signResponse.signature)
    }
}
