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
}

protocol VisaOnboardingTangemWalletApproveDataProvider: AnyObject {
    func loadDataToSign() async throws -> Data
}

final class VisaOnboardingTangemWalletConfirmationViewModel: ObservableObject {
    typealias ApprovePair = (userWalletModel: UserWalletModel, walletModel: Wallet.PublicKey)
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var isLoading: Bool = false

    private let targetWalletAddress: String
    private var approvePair: ApprovePair?

    private let tangemSdk: TangemSdk

    private weak var delegate: VisaOnboardingTangemWalletApproveDelegate?
    private weak var dataProvider: VisaOnboardingTangemWalletApproveDataProvider?

    private var approveCancellableTask: AnyCancellable?

    init(
        targetWalletAddress: String,
        tangemSdk: TangemSdk,
        delegate: VisaOnboardingTangemWalletApproveDelegate,
        dataProvider: VisaOnboardingTangemWalletApproveDataProvider
    ) {
        self.targetWalletAddress = targetWalletAddress
        self.tangemSdk = tangemSdk
        self.delegate = delegate
        self.dataProvider = dataProvider
    }

    convenience init(
        approvePair: ApprovePair,
        targetWalletAddress: String,
        tangemSdk: TangemSdk,
        delegate: VisaOnboardingTangemWalletApproveDelegate,
        dataProvider: VisaOnboardingTangemWalletApproveDataProvider
    ) {
        self.init(
            targetWalletAddress: targetWalletAddress,
            tangemSdk: tangemSdk,
            delegate: delegate,
            dataProvider: dataProvider
        )
        self.approvePair = approvePair
    }

    func approveAction() {
        guard approveCancellableTask == nil else {
            return
        }

        approveCancellableTask = Task { [weak self] in
            guard let self else { return }

            guard let dataToSign = try await dataProvider?.loadDataToSign() else {
                approveCancellableTask = nil
                return
            }

            try Task.checkCancellation()

            try await signData(dataToSign)

            approveCancellableTask = nil
        }.eraseToAnyCancellable()
    }
}

private extension VisaOnboardingTangemWalletConfirmationViewModel {
    func signData(_ dataToSign: Data) async throws {
        let task = VisaCustomerWalletApproveTask(targetAddress: targetWalletAddress, approveData: dataToSign)
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
}
