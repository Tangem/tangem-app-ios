//
//  UserWalletListViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit

final class UserWalletListViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) var failedCardScanTracker: FailedScanTrackable

    // MARK: - ViewState

    @Published var multiCurrencyModels: [UserWalletListCellViewModel] = []
    @Published var singleCurrencyModels: [UserWalletListCellViewModel] = []
    @Published var isScanningCard = false
    @Published var error: AlertBinder?
    @Published var showTroubleshootingView: Bool = false
    @Published var showingDeleteConfirmation: Bool = false

    // MARK: - Dependencies

    var unlockAllButtonTitle: String {
        Localization.userWalletListUnlockAll(BiometricAuthorizationUtils.biometryType.name)
    }

    var isLocked: Bool {
        userWalletRepository.isLocked
    }

    private unowned let coordinator: UserWalletListRoutable
    private var bag: Set<AnyCancellable> = []
    private var userWalletIdToBeDeleted: Data?
    private var selectedUserWalletId: Data?

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator

        Analytics.log(.myWalletsScreenOpened)
        selectedUserWalletId = userWalletRepository.selectedUserWalletId
        updateModels()

        bind()
    }

    func bind() {
        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                switch event {
                case .locked:
                    break
                case .scan(let isScanning):
                    self?.isScanningCard = isScanning
                case .updated(let userWalletModel):
                    self?.update(userWalletModel: userWalletModel)
                case .deleted(let userWalletId):
                    self?.delete(userWalletId: userWalletId)
                case .selected(let userWallet, let reason):
                    self?.setSelectedWallet(userWallet, reason: reason)
                case .inserted:
                    break
                }
            }
            .store(in: &bag)
    }

    func unlockAllWallets() {
        Analytics.log(.buttonUnlockAllWithFaceID)

        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            if case .error = result {
                return
            }

            self?.updateModels()
        }
    }

    func addUserWallet() {
        Analytics.beginLoggingCardScan(source: .myWalletsNewCard)

        userWalletRepository.add { [weak self] result in
            guard
                let self,
                let result
            else {
                return
            }

            switch result {
            case .troubleshooting:
                self.showTroubleshootingView = true
            case .onboarding(let input):
                self.openOnboarding(with: input)
            case .error(let error):
                if let saltPayError = error as? SaltPayRegistratorError {
                    self.error = saltPayError.alertBinder
                } else if let userWalletRepositoryError = error as? UserWalletRepositoryError {
                    self.error = userWalletRepositoryError.alertBinder
                } else {
                    self.error = error.alertBinder
                }
            case .success(let cardModel):
                self.add(cardModel: cardModel)
            }
        }
    }

    func tryAgain() {
        addUserWallet()
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()

        coordinator.openMail(with: failedCardScanTracker, emailType: .failedToScanCard, recipient: EmailConfig.default.recipient)
    }

    func edit(_ userWallet: UserWallet) {
        Analytics.log(.buttonEditWalletTapped)

        let alert = UIAlertController(title: Localization.userWalletListRenamePopupTitle, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Localization.commonCancel, style: .cancel) { _ in }
        alert.addAction(cancelAction)

        var nameTextField: UITextField?
        alert.addTextField { textField in
            nameTextField = textField
            nameTextField?.placeholder = Localization.userWalletListRenamePopupPlaceholder
            nameTextField?.text = userWallet.name
            nameTextField?.clearButtonMode = .whileEditing
            nameTextField?.autocapitalizationType = .sentences
        }

        let acceptButton = UIAlertAction(title: Localization.commonOk, style: .default) { [weak self, nameTextField] _ in
            let newName = nameTextField?.text ?? ""

            guard userWallet.name != newName else { return }

            var newUserWallet = userWallet
            newUserWallet.name = newName

            self?.userWalletRepository.save(newUserWallet)
        }
        alert.addAction(acceptButton)

        AppPresenter.shared.show(alert)
    }

    func showDeletionConfirmation(_ userWallet: UserWallet) {
        Analytics.log(.buttonDeleteWalletTapped)

        showingDeleteConfirmation = true
        userWalletIdToBeDeleted = userWallet.userWalletId
    }

    func didCancelWalletDeletion() {
        userWalletIdToBeDeleted = nil
    }

    func didConfirmWalletDeletion() {
        let viewModels = (multiCurrencyModels + singleCurrencyModels)
        guard let viewModel = viewModels.first(where: { $0.userWalletId == userWalletIdToBeDeleted }) else {
            return
        }

        userWalletRepository.delete(viewModel.userWallet, logoutIfNeeded: true)
    }

    private func setSelectedWallet(_ userWallet: UserWallet, reason: UserWalletRepositorySelectionChangeReason) {
        selectedUserWalletId = userWallet.userWalletId
        updateSelectedWalletModel()

        switch reason {
        case .userSelected, .inserted:
            coordinator.dismiss()
        case .deleted:
            break
        }
    }

    private func updateModels() {
        let oldModels = multiCurrencyModels + singleCurrencyModels
        let totalBalanceProviders = Dictionary(oldModels.map {
            ($0.userWalletId, $0.totalBalanceProvider)
        }, uniquingKeysWith: { v1, _ in
            v1
        })

        multiCurrencyModels = userWalletRepository.models
            .filter { $0.isMultiWallet }
            .compactMap { $0.userWalletModel }
            .map {
                mapToUserWalletListCellViewModel(userWalletModel: $0, totalBalanceProvider: totalBalanceProviders[$0.userWallet.userWalletId])
            }

        singleCurrencyModels = userWalletRepository.models
            .filter { !$0.isMultiWallet }
            .compactMap { $0.userWalletModel }
            .map {
                mapToUserWalletListCellViewModel(userWalletModel: $0, totalBalanceProvider: totalBalanceProviders[$0.userWallet.userWalletId])
            }
    }

    private func update(userWalletModel: UserWalletModel) {
        let userWalletId = userWalletModel.userWallet.userWalletId

        if let index = multiCurrencyModels.firstIndex(where: { $0.userWalletId == userWalletId }) {
            multiCurrencyModels[index] = mapToUserWalletListCellViewModel(
                userWalletModel: userWalletModel,
                totalBalanceProvider: multiCurrencyModels[index].totalBalanceProvider
            )
        } else if let index = singleCurrencyModels.firstIndex(where: { $0.userWalletId == userWalletId }) {
            singleCurrencyModels[index] = mapToUserWalletListCellViewModel(
                userWalletModel: userWalletModel,
                totalBalanceProvider: singleCurrencyModels[index].totalBalanceProvider
            )
        }
    }

    private func delete(userWalletId: Data) {
        userWalletIdToBeDeleted = nil

        multiCurrencyModels.removeAll { $0.userWalletId == userWalletId }
        singleCurrencyModels.removeAll { $0.userWalletId == userWalletId }
    }

    private func updateSelectedWalletModel() {
        let models = multiCurrencyModels + singleCurrencyModels
        for model in models {
            model.isSelected = selectedUserWalletId == model.userWalletId
        }
    }

    private func openOnboarding(with input: OnboardingInput) {
        DispatchQueue.main.async {
            self.coordinator.openOnboarding(with: input)
        }
    }

    func add(cardModel: CardViewModel) {
        guard
            let cellModel = cardModel.userWalletModel.map({ mapToUserWalletListCellViewModel(userWalletModel: $0) })
        else {
            return
        }

        if cardModel.isMultiWallet {
            multiCurrencyModels.append(cellModel)
        } else {
            singleCurrencyModels.append(cellModel)
        }
    }

    private func mapToUserWalletListCellViewModel(userWalletModel: UserWalletModel, totalBalanceProvider: TotalBalanceProviding? = nil) -> UserWalletListCellViewModel {
        let userWallet = userWalletModel.userWallet
        let config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        let subtitle: String = {
            if let embeddedBlockchain = config.embeddedBlockchain {
                return embeddedBlockchain.blockchainNetwork.blockchain.displayName
            }

            return Localization.cardLabelCardCount(config.cardsCount)
        }()

        return UserWalletListCellViewModel(
            userWalletModel: userWalletModel,
            subtitle: subtitle,
            isMultiWallet: config.hasFeature(.multiCurrency),
            isUserWalletLocked: userWallet.isLocked,
            isSelected: selectedUserWalletId == userWallet.userWalletId,
            totalBalanceProvider: totalBalanceProvider ?? TotalBalanceProvider(userWalletModel: userWalletModel, userWalletAmountType: config.cardAmountType),
            cardImageProvider: CardImageProvider()
        ) { [weak self] in
            if userWallet.isLocked {
                Analytics.beginLoggingCardScan(source: .myWalletsUnlock)
            }
            self?.userWalletRepository.setSelectedUserWalletId(userWallet.userWalletId, reason: .userSelected)
        } didEditUserWallet: { [weak self] in
            self?.edit(userWallet)
        } didDeleteUserWallet: { [weak self] in
            self?.showDeletionConfirmation(userWallet)
        }
    }
}
