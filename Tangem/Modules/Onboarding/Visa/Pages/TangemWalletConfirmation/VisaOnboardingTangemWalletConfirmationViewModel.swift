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

struct VisaWalletPublicKeySearchUtility {
    private let visaUtilities = VisaUtilities()

    func findPublicKey(targetAddress: String, derivationPath: DerivationPath?, on card: Card) throws (SearchError) -> Data {
        if let derivationPath {
            return try findKeyWithDerivation(targetAddress: targetAddress, derivationPath: derivationPath, on: card)
        } else {
            return try findKeyWithoutDerivation(targetAddress: targetAddress, on: card)
        }
    }

    func validatePublicKey(targetAddress: String, publicKey: Data) throws (SearchError) {
        let addressService = visaUtilities.addressService

        let createdAddress: Address
        do {
            createdAddress = try addressService.makeAddress(
                for: .init(seedKey: publicKey, derivationType: .none),
                with: .default
            )
        } catch {
            throw .failedToGenerateAddress(error)
        }

        try validateCreatedAddress(targetAddress: targetAddress, createdAddress: createdAddress)
    }

    func validateExtendedPublicKey(
        targetAddress: String,
        extendedPublicKey: ExtendedPublicKey,
        derivationPath: DerivationPath
    ) throws (SearchError) {
        let addressService = visaUtilities.addressService

        let createdAddress: Address
        do {
            createdAddress = try addressService.makeAddress(
                for: .init(
                    seedKey: extendedPublicKey.publicKey,
                    derivationType: .plain(.init(
                        path: derivationPath,
                        extendedPublicKey: extendedPublicKey
                    ))
                ),
                with: .default
            )
        } catch {
            throw .failedToGenerateAddress(error)
        }

        try validateCreatedAddress(targetAddress: targetAddress, createdAddress: createdAddress)
    }

    private func findKeyWithoutDerivation(targetAddress: String, on card: Card) throws (SearchError) -> Data {
        guard let wallet = card.wallets.first(where: { $0.curve == visaUtilities.visaBlockchain.curve }) else {
            throw SearchError.missingWalletOnTargetCurve
        }

        try validatePublicKey(targetAddress: targetAddress, publicKey: wallet.publicKey)

        return wallet.publicKey
    }

    private func findKeyWithDerivation(targetAddress: String, derivationPath: DerivationPath, on card: Card) throws (SearchError) -> Data {
        guard let wallets = card.wallets.first(where: { $0.curve == visaUtilities.visaBlockchain.curve }) else {
            throw SearchError.missingWalletOnTargetCurve
        }

        guard let targetWallet = wallets.derivedKeys.keys[derivationPath] else {
            throw SearchError.missingDerivedKeys
        }

        try validateExtendedPublicKey(targetAddress: targetAddress, extendedPublicKey: targetWallet, derivationPath: derivationPath)

        return targetWallet.publicKey
    }

    private func validateCreatedAddress(targetAddress: String, createdAddress: any Address) throws (SearchError) {
        guard createdAddress.value == targetAddress else {
            throw SearchError.addressesNotMatch
        }
    }
}

extension VisaWalletPublicKeySearchUtility {
    enum SearchError: Error {
        case missingWalletOnTargetCurve
        case missingDerivedKeys
        case failedToGenerateAddress(Error)
        case addressesNotMatch
        case noDerivationPathForProvidedDerivationStyle
    }
}

class VisaCustomerWalletApproveTask: CardSessionRunnable {
    typealias TaskResult = CompletionResult<SignHashResponse>
    private let targetAddress: String
    private let approveData: Data

    private let visaUtilities = VisaUtilities()
    private let pubKeySearchUtility = VisaWalletPublicKeySearchUtility()

    init(
        targetAddress: String,
        approveData: Data
    ) {
        self.targetAddress = targetAddress
        self.approveData = approveData
    }

    func run(in session: CardSession, completion: @escaping TaskResult) {
        let scanCard = AppScanTask()
        scanCard.run(in: session) { result in
            switch result {
            case .success(let response):
                self.proceedApprove(scanResponse: response, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension VisaCustomerWalletApproveTask {
    func proceedApprove(scanResponse: AppScanTaskResponse, in session: CardSession, completion: @escaping TaskResult) {
        let config = UserWalletConfigFactory(scanResponse.getCardInfo()).makeConfig()

        guard let derivationStyle = config.derivationStyle else {
            proceedApproveWithLegacyCard(card: scanResponse.card, in: session, completion: completion)
            return
        }

        guard let derivationPath = visaUtilities.visaDefaultDerivationPath(style: derivationStyle) else {
            // Is this possible?..
            return
        }

        do {
            let searchUtility = VisaWalletPublicKeySearchUtility()
            let walletPublicKey = try searchUtility.findPublicKey(
                targetAddress: targetAddress,
                derivationPath: derivationPath,
                on: scanResponse.card
            )

            signApproveData(
                targetWalletPublicKey: walletPublicKey,
                derivationPath: derivationPath,
                in: session,
                completion: completion
            )
        } catch {
            switch error {
            case .missingDerivedKeys:
                deriveKeys(scanResponse: scanResponse, derivationPath: derivationPath, in: session, completion: completion)
            default:
                completion(.failure(.underlying(error: error)))
            }
        }
    }

    func proceedApproveWithLegacyCard(card: Card, in session: CardSession, completion: @escaping TaskResult) {
        do {
            let searchUtility = VisaWalletPublicKeySearchUtility()
            let publicKey = try searchUtility.findPublicKey(targetAddress: targetAddress, derivationPath: nil, on: card)
            signApproveData(targetWalletPublicKey: publicKey, derivationPath: nil, in: session, completion: completion)
        } catch {
            completion(.failure(.underlying(error: error)))
        }
    }

    func deriveKeys(
        scanResponse: AppScanTaskResponse,
        derivationPath: DerivationPath,
        in session: CardSession,
        completion: @escaping TaskResult
    ) {
        let targetCurve = visaUtilities.visaBlockchain.curve
        guard let wallet = scanResponse.card.wallets.first(where: { $0.curve == targetCurve }) else {
            completion(.failure(.walletNotFound))
            return
        }

        let derivationTask = DeriveWalletPublicKeyTask(walletPublicKey: wallet.publicKey, derivationPath: derivationPath)
        derivationTask.run(in: session) { result in
            switch result {
            case .success(let extendedPubKey):
                self.signApproveData(
                    targetWalletPublicKey: extendedPubKey.publicKey,
                    derivationPath: derivationPath,
                    in: session,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func signApproveData(
        targetWalletPublicKey: Data,
        derivationPath: DerivationPath?,
        in session: CardSession,
        completion: @escaping TaskResult
    ) {
        let signTask = SignHashCommand(
            hash: approveData,
            walletPublicKey: targetWalletPublicKey,
            derivationPath: derivationPath
        )

        signTask.run(in: session, completion: completion)
    }
}
