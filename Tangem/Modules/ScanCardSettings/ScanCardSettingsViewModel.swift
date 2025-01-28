//
//  ScanCardSettingsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class ScanCardSettingsViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var icon: LoadingValue<CardImageResult> = .loading
    @Published var isLoading: Bool = false
    @Published var alert: AlertBinder?

    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>
    private let cardScanner: CardScanner
    private weak var coordinator: ScanCardSettingsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        input: ScanCardSettingsViewModel.Input,
        coordinator: ScanCardSettingsRoutable
    ) {
        cardImagePublisher = input.cardImagePublisher
        cardScanner = input.cardScanner
        self.coordinator = coordinator

        bind()
    }

    func bind() {
        cardImagePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, image in
                viewModel.icon = .loaded(image)
            }
            .store(in: &bag)
    }

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
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        isLoading = true
        cardScanner.scanCard { [weak self] result in
            self?.isLoading = false

            switch result {
            case .failure(let error):
                guard !error.isUserCancelled else {
                    return
                }

                AppLog.shared.error(error)
                Analytics.tryLogCardVerificationError(error, source: .settings)
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.getCardInfo()))
            }
        }
    }

    func showErrorAlert(error: Error) {
        alert = error.alertBinder
    }

    func processSuccessScan(for cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        // We just allow to reset cards without keys via any wallet
        let userWalletId = config.userWalletIdSeed.map { UserWalletId(with: $0) } ?? UserWalletId(value: Data())

        let input = CardSettingsViewModel.Input(
            userWalletId: userWalletId,
            recoveryInteractor: UserCodeRecoveringCardInteractor(with: cardInfo),
            securityOptionChangeInteractor: SecurityOptionChangingCardInteractor(with: cardInfo),
            factorySettingsResettingCardInteractor: FactorySettingsResettingCardInteractor(with: cardInfo),
            isResetToFactoryAvailable: !config.getFeatureAvailability(.resetToFactory).isHidden,
            backupCardsCount: cardInfo.card.backupStatus?.backupCardsCount ?? 0,
            canTwin: config.hasFeature(.twinning),
            twinInput: makeTwinInput(from: cardInfo, config: config, userWalletId: userWalletId),
            cardIdFormatted: cardInfo.cardIdFormatted,
            cardIssuer: cardInfo.card.issuer.name,
            canDisplayHashesCount: config.hasFeature(.displayHashesCount),
            cardSignedHashes: cardInfo.card.walletSignedHashes,
            canChangeAccessCodeRecoverySettings: config.hasFeature(.accessCodeRecoverySettings),
            resetToFactoryDisabledLocalizedReason: config.getDisabledLocalizedReason(for: .resetToFactory)
        )

        coordinator?.openCardSettings(with: input)
    }

    func makeTwinInput(from cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> OnboardingInput? {
        guard let twinData = cardInfo.walletData.twinData else {
            return nil
        }

        let factory = TwinInputFactory(
            firstCardId: cardInfo.card.cardId,
            cardInput: .cardInfo(cardInfo),
            userWalletToDelete: userWalletId,
            twinData: twinData,
            sdkFactory: config
        )
        return factory.makeTwinInput()
    }
}

extension ScanCardSettingsViewModel {
    struct Input {
        let cardImagePublisher: AnyPublisher<CardImageResult, Never>
        let cardScanner: CardScanner
    }
}
