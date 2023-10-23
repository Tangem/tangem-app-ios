//
//  ResetToFactoryViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class ResetToFactoryViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var accessToCardWarningSelected: Bool = false
    @Published var accessCodeRecoveryWarningSelected: Bool = false

    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    var actionButtonIsEnabled: Bool {
        accessToCardWarningSelected && accessCodeRecoveryWarningSelected
    }

    var message: String {
        if hasBackupCards {
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    let hasBackupCards: Bool

    private let cardInteractor: CardResettable
    private let userWalletId: UserWalletId
    private unowned let coordinator: ResetToFactoryViewRoutable

    init(input: ResetToFactoryViewModel.Input, coordinator: ResetToFactoryViewRoutable) {
        cardInteractor = input.cardInteractor
        userWalletId = input.userWalletId
        hasBackupCards = input.hasBackupCards
        self.coordinator = coordinator
    }

    func didTapMainButton() {
        showConfirmationAlert()
    }
}

private extension ResetToFactoryViewModel {
    func showConfirmationAlert() {
        let sheet = ActionSheet(
            title: Text(Localization.cardSettingsActionSheetTitle),
            buttons: [
                .destructive(Text(Localization.cardSettingsActionSheetReset)) { [weak self] in
                    self?.resetCardToFactory()
                },
                .cancel(Text(Localization.commonCancel)),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func resetCardToFactory() {
        cardInteractor.resetCard { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                Analytics.log(.factoryResetFinished)
                userWalletRepository.delete(userWalletId, logoutIfNeeded: false)
                coordinator.dismiss()
            case .failure(let error):
                if !error.isUserCancelled {
                    AppLog.shared.error(error, params: [.action: .purgeWallet])
                    alert = error.alertBinder
                }
            }
        }
    }
}
