//
//  UserWalletSettingsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - ViewState

    @Published private(set) var name: String
    @Published var accountsSection: [AccountsSectionType] = []
    @Published var backupViewModel: DefaultRowViewModel?

    var commonSectionModels: [DefaultRowViewModel] {
        [manageTokensViewModel, cardSettingsViewModel, refferalViewModel].compactMap { $0 }
    }

    @Published var forgetViewModel: DefaultRowViewModel?

    @Published var alert: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    // MARK: - Private

    @Published private var manageTokensViewModel: DefaultRowViewModel?
    @Published private var cardSettingsViewModel: DefaultRowViewModel?
    @Published private var refferalViewModel: DefaultRowViewModel?

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private weak var coordinator: UserWalletSettingsRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        coordinator: UserWalletSettingsRoutable
    ) {
        name = userWalletModel.name

        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        setupView()
    }

    func onTapNameField() {
        guard AppSettings.shared.saveUserWallets else { return }

        if let alert = AlertBuilder.makeWalletRenamingAlert(
            userWalletRepository: userWalletRepository,
            updateName: { self.name = $0 }
        ) {
            AppPresenter.shared.show(alert)
        }
    }
}

// MARK: - Private

private extension UserWalletSettingsViewModel {
    func setupView() {
        // setupAccountsSection()
        setupViewModels()
    }

    func setupAccountsSection() {
        // TODO:
        accountsSection = []
    }

    func setupViewModels() {
        if !userWalletModel.config.getFeatureAvailability(.backup).isHidden {
            backupViewModel = DefaultRowViewModel(
                title: Localization.detailsRowTitleCreateBackup,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.prepareBackup)
            )
        } else {
            backupViewModel = nil
        }

        if userWalletModel.config.hasFeature(.multiCurrency) {
            manageTokensViewModel = .init(
                title: Localization.mainManageTokens,
                action: weakify(self, forFunction: UserWalletSettingsViewModel.openManageTokens)
            )
        }

        cardSettingsViewModel = DefaultRowViewModel(
            title: Localization.cardSettingsTitle,
            action: weakify(self, forFunction: UserWalletSettingsViewModel.openCardSettings)
        )

        if !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden {
            refferalViewModel =
                DefaultRowViewModel(
                    title: Localization.detailsReferralTitle,
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.openReferral)
                )
        } else {
            refferalViewModel = nil
        }

        forgetViewModel = DefaultRowViewModel(
            title: Localization.settingsForgetWallet,
            action: weakify(self, forFunction: UserWalletSettingsViewModel.didTapDeleteWallet)
        )
    }

    // MARK: - Actions

    func bind() {
        $name
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, name in
                viewModel.userWalletModel.updateWalletName(name.trimmed())
            })
            .store(in: &bag)
    }

    func prepareBackup() {
        Analytics.log(.buttonCreateBackup)
        if let backupInput = userWalletModel.backupInput {
            openOnboarding(with: backupInput)
        }
    }

    func didTapDeleteWallet() {
        Analytics.log(.buttonDeleteWalletTapped)

        let sheet = ActionSheet(
            title: Text(Localization.userWalletListDeletePrompt),
            buttons: [
                .destructive(
                    Text(Localization.commonDelete),
                    action: weakify(self, forFunction: UserWalletSettingsViewModel.didConfirmWalletDeletion)
                ),
                .cancel(Text(Localization.commonCancel)),
            ]
        )
        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func didConfirmWalletDeletion() {
        userWalletRepository.delete(userWalletModel.userWalletId)
        coordinator?.dismiss()
    }

    func showErrorAlert(error: Error) {
        alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
    }
}

// MARK: - Navigation

private extension UserWalletSettingsViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboardingModal(with: input)
    }

    func openManageTokens() {
        Analytics.log(.settingsButtonManageTokens)

        coordinator?.openManageTokens(userWalletModel: userWalletModel)
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings)

        let scanParameters = CardScannerParameters(
            shouldAskForAccessCodes: true,
            performDerivations: false,
            sessionFilter: userWalletModel.config.cardSessionFilter
        )

        let scanner = CardScannerFactory().makeScanner(
            with: userWalletModel.config.makeTangemSdk(),
            parameters: scanParameters
        )

        coordinator?.openScanCardSettings(
            with: .init(
                cardImagePublisher: userWalletModel.cardImagePublisher,
                cardScanner: scanner
            )
        )
    }

    func openReferral() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .referralProgram) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            userTokensManager: userWalletModel.userTokensManager
        )

        coordinator?.openReferral(input: input)
    }
}

extension UserWalletSettingsViewModel {
    enum AccountsSectionType: Identifiable {
        case header
        case account(DefaultRowViewModel) // TODO:
        case addNewAccountButton(DefaultRowViewModel)

        var id: Int {
            switch self {
            case .header:
                return "header".hashValue
            case .account(let viewModel):
                return viewModel.id.hashValue
            case .addNewAccountButton(let viewModel):
                return viewModel.id.hashValue
            }
        }
    }
}
