//
//  ScanCardSettingsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

final class ScanCardSettingsViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let id = UUID()

    @Published var isLoading: Bool = false
    @Published var alert: AlertBinder?

    private let sessionFilter: SessionFilter
    private let sdk: TangemSdk
    private weak var coordinator: ScanCardSettingsRoutable?

    init(sessionFilter: SessionFilter, sdk: TangemSdk, coordinator: ScanCardSettingsRoutable) {
        self.sessionFilter = sessionFilter
        self.sdk = sdk
        self.coordinator = coordinator
    }
}

// MARK: - View Output

extension ScanCardSettingsViewModel {
    func scanCard() {
        scan { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cardInfo):
                processSuccessScan(for: cardInfo)
            case .failure(let error):
                showErrorAlert(error: error)
            }
        }
    }

    private func processSuccessScan(for cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else {
            return
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        let input = CardSettingsViewModel.Input(
            userWalletId: userWalletId,
            recoveryInteractor: UserCodeRecoveringCardInteractor(with: cardInfo),
            securityOptionChangeInteractor: SecurityOptionChangingCardInteractor(with: cardInfo),
            factorySettingsResettingCardInteractor: FactorySettingsResettingCardInteractor(with: cardInfo),
            isResetToFactoryAvailable: !config.getFeatureAvailability(.resetToFactory).isHidden,
            hasBackupCards: cardInfo.card.backupStatus?.isActive ?? false,
            canTwin: config.hasFeature(.twinning),
            twinInput: makeTwinInput(from: cardInfo, config: config, userWalletId: userWalletId),
            cardIdFormatted: cardInfo.cardIdFormatted,
            cardIssuer: cardInfo.card.issuer.name,
            canDisplayHashesCount: config.hasFeature(.displayHashesCount),
            cardSignedHashes: cardInfo.card.walletSignedHashes,
            canChangeAccessCodeRecoverySettings: config.hasFeature(.accessCodeRecoverySettings),
            resetTofactoryDisabledLocalizedReason: config.getDisabledLocalizedReason(for: .resetToFactory)
        )

        coordinator?.openCardSettings(with: input)
    }

    private func makeTwinInput(from cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> OnboardingInput? {
        guard let twinData = cardInfo.walletData.twinData,
              let existingModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        let factory = TwinInputFactory(
            firstCardId: cardInfo.card.cardId,
            cardInput: .userWalletModel(existingModel),
            userWalletToDelete: userWalletId,
            twinData: twinData,
            sdkFactory: config
        )
        return factory.makeTwinInput()
    }
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        isLoading = true
        let task = AppScanTask(shouldAskForAccessCode: true)
        sdk.startSession(with: task, filter: sessionFilter) { [weak self] result in
            self?.isLoading = false

            switch result {
            case .failure(let error):
                guard !error.isUserCancelled else {
                    return
                }

                AppLog.shared.error(error)
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.getCardInfo()))
            }
        }
    }

    func showErrorAlert(error: Error) {
        alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
    }
}
