//
//  VisaOnboardingTangemWalletDeployApproveViewModel.swift
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

protocol VisaOnboardingTangemWalletApproveDelegate: VisaOnboardingAlertPresenter {
    func processSignedData(_ signedData: Data) async throws
}

protocol VisaOnboardingTangemWalletApproveDataProvider: AnyObject {
    func loadDataToSign() async throws -> Data
}

final class VisaOnboardingTangemWalletDeployApproveViewModel: ObservableObject {
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
            log("Approve task already exists")
            return
        }

        isLoading = true
        approveCancellableTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                guard let dataToSign = try await dataProvider?.loadDataToSign() else {
                    await processApproveActionResult(.failure("Failed to get data to sign"))
                    return
                }

                try Task.checkCancellation()

                log("Attempt to sign loaded data: \(dataToSign.hexString)")
                let signHashResponse: SignHashResponse
                if let approvePair {
                    signHashResponse = try await signDataWithTargetPair(approvePair, dataToSign: dataToSign)
                } else {
                    signHashResponse = try await signData(dataToSign)
                }

                log("Receive sign hash response. Sending data to delegate")
                try await delegate?.processSignedData(signHashResponse.signature)
                await processApproveActionResult(.success(()))
            } catch {
                await processApproveActionResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }

    @MainActor
    private func processApproveActionResult(_ result: Result<Void, Error>) async {
        switch result {
        case .success:
            // Right now we don't have any specific UI updates for successful scenario
            break
        case .failure(let error):
            log("Failed to sign approve data. Error: \(error)")
            if !error.isCancellationError {
                await delegate?.showAlert(error.alertBinder)
            }
        }
        isLoading = false
        approveCancellableTask = nil
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[VisaOnboardingApproveViewModel] - \(message())")
    }
}

private extension VisaOnboardingTangemWalletDeployApproveViewModel {
    func signData(_ dataToSign: Data) async throws -> SignHashResponse {
        log("Attempt to sign data with unknown wallet pair. Creating VisaCustomerWalletApproveTask")
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

        log("Sign approve data successfully finished")
        return signResponse
    }

    func signDataWithTargetPair(_ approvePair: ApprovePair, dataToSign: Data) async throws -> SignHashResponse {
        log("Attempt to sign data with saved in repository wallet pair. Creating plain SignHashCommand")
        let signHashTask = SignHashCommand(hash: dataToSign, walletPublicKey: approvePair.publicKey, derivationPath: approvePair.derivationPath)
        let signResponse: SignHashResponse = try await withCheckedThrowingContinuation { continuation in
            approvePair.tangemSdk.startSession(with: signHashTask, filter: approvePair.sessionFilter) { result in
                switch result {
                case .success(let hashResponse):
                    continuation.resume(returning: hashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        log("Sign approve data with known approve pair successfully finished")
        return signResponse
    }
}

extension VisaOnboardingTangemWalletDeployApproveViewModel {
    struct ApprovePair {
        let sessionFilter: SessionFilter
        let publicKey: Data
        let derivationPath: DerivationPath?
        let tangemSdk: TangemSdk
    }
}
