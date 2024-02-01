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

    @Published var warnings: [Warning] = []
    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    var actionButtonIsEnabled: Bool {
        warnings.allConforms(\.isAccepted)
    }

    var message: String {
        if hasBackupCards {
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    private let hasBackupCards: Bool
    private let cardInteractor: CardResettable
    private let userWalletId: UserWalletId
    private weak var coordinator: ResetToFactoryViewRoutable?

    init(input: ResetToFactoryViewModel.Input, coordinator: ResetToFactoryViewRoutable) {
        cardInteractor = input.cardInteractor
        userWalletId = input.userWalletId
        hasBackupCards = input.hasBackupCards
        self.coordinator = coordinator

        setupView()
    }

    func didTapMainButton() {
        showConfirmationAlert()
    }

    func toggleWarning(warningType: WarningType) {
        guard let index = warnings.firstIndex(where: { $0.type == warningType }) else {
            return
        }

        warnings[index].isAccepted.toggle()
    }
}

private extension ResetToFactoryViewModel {
    func setupView() {
        warnings.append(Warning(isAccepted: false, type: .accessToCard))

        if hasBackupCards {
            warnings.append(Warning(isAccepted: false, type: .accessCodeRecovery))
        }
    }

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
                coordinator?.dismiss()
            case .failure(let error):
                if !error.isUserCancelled {
                    AppLog.shared.error(error, params: [.action: .purgeWallet])
                    alert = error.alertBinder
                }
            }
        }
    }
}

extension ResetToFactoryViewModel {
    struct Warning: Identifiable, Hashable {
        var id: Int { hashValue }

        var isAccepted: Bool
        let type: WarningType
    }

    enum WarningType: String, CaseIterable, Hashable {
        case accessToCard
        case accessCodeRecovery

        var title: String {
            switch self {
            case .accessToCard:
                return Localization.resetCardToFactoryCondition1
            case .accessCodeRecovery:
                return Localization.resetCardToFactoryCondition2
            }
        }
    }
}
