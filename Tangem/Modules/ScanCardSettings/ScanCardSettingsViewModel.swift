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
    let id = UUID()

    @Published var isLoading: Bool = false
    @Published var alert: AlertBinder?

    private let expectedUserWalletId: Data
    private let sdk: TangemSdk
    private unowned let coordinator: ScanCardSettingsRoutable

    init(expectedUserWalletId: Data, sdk: TangemSdk, coordinator: ScanCardSettingsRoutable) {
        self.expectedUserWalletId = expectedUserWalletId
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
        guard let cardModel = CardViewModel(cardInfo: cardInfo) else { return }

        guard cardModel.userWalletId.value == expectedUserWalletId else {
            showErrorAlert(error: AppError.wrongCardWasTapped)
            return
        }

        coordinator.openCardSettings(cardModel: cardModel)
    }
}

// MARK: - Private

extension ScanCardSettingsViewModel {
    func scan(completion: @escaping (Result<CardInfo, Error>) -> Void) {
        isLoading = true
        let task = AppScanTask(shouldAskForAccessCode: true)
        sdk.startSession(with: task) { [weak self] result in
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
