//
//  UncompletedBackupViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

final class UncompletedBackupViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var discardAlert: ActionSheetBinder?
    @Published var error: AlertBinder?

    private unowned let coordinator: UncompletedBackupRoutable

    private lazy var backupHelper = BackupHelper()

    init(
        coordinator: UncompletedBackupRoutable
    ) {
        self.coordinator = coordinator
    }

    func onAppear() {
        showAlert()
    }

    private func showAlert() {
        let alert = Alert(
            title: Text(Localization.commonWarning),
            message: Text(Localization.welcomeInterruptedBackupAlertMessage),
            primaryButton: .default(Text(Localization.welcomeInterruptedBackupAlertResume), action: continueBackup),
            secondaryButton: .destructive(Text(Localization.welcomeInterruptedBackupAlertDiscard), action: showExtraDiscardAlert)
        )

        error = AlertBinder(alert: alert)
    }

    private func showExtraDiscardAlert() {
        let buttonResume: ActionSheet.Button = .cancel(Text(Localization.welcomeInterruptedBackupDiscardResume), action: continueBackup)
        let buttonDiscard: ActionSheet.Button = .destructive(Text(Localization.welcomeInterruptedBackupDiscardDiscard), action: discardBackup)
        let sheet = ActionSheet(
            title: Text(Localization.welcomeInterruptedBackupDiscardTitle),
            message: Text(Localization.welcomeInterruptedBackupDiscardMessage),
            buttons: [buttonDiscard, buttonResume]
        )

        DispatchQueue.main.async {
            self.discardAlert = ActionSheetBinder(sheet: sheet)
        }
    }

    private func continueBackup() {
        guard let cardId = backupHelper.cardId else {
            return
        }

        let backupServiceFactory: BackupServiceFactory = backupHelper.hasIncompletedSaltPayBackup
            ? SaltPayBackupServiceFactory(cardId: cardId, isAccessCodeSet: false)
            : GenericBackupServiceFactory(isAccessCodeSet: false)

        let factory = ResumeBackupInputFactory(
            cardId: cardId,
            tangemSdkFactory: TangemSdkDefaultFactory(),
            backupServiceFactory: backupServiceFactory
        )
        openBackup(with: factory.makeBackupInput())
    }

    private func discardBackup() {
        backupHelper.discardIncompletedBackup()
        dismiss()
    }
}

// MARK: - Navigation

extension UncompletedBackupViewModel {
    func openBackup(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func dismiss() {
        coordinator.dismiss()
    }
}
