//
//  AppSettingsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

class AppSettingsViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: ViewState

    @Published var warningViewModel: DefaultWarningRowViewModel?
    @Published var savingWalletViewModel: DefaultToggleRowViewModel?
    @Published var savingAccessCodesViewModel: DefaultToggleRowViewModel?
    @Published var currencySelectionViewModel: DefaultRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: Dependencies

    private unowned let coordinator: AppSettingsRoutable

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var isBiometryAvailable: Bool = true

    private var isSavingWallet: Bool {
        didSet {
            savingWalletViewModel?.update(isOn: isSavingWalletBinding())
            AppSettings.shared.saveUserWallets = isSavingWallet
        }
    }

    private var isSavingAccessCodes: Bool {
        didSet {
            savingAccessCodesViewModel?.update(isOn: isSavingAccessCodesBinding())
            AppSettings.shared.saveAccessCodes = isSavingAccessCodes
        }
    }

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var selectedCurrencyCode: String = "USD"

    init(coordinator: AppSettingsRoutable) {
        self.coordinator = coordinator

        let isSavingWallet = AppSettings.shared.saveUserWallets
        self.isSavingWallet = isSavingWallet
        isSavingAccessCodes = isSavingWallet && AppSettings.shared.saveAccessCodes

        updateView()
        bind()
    }
}

// MARK: - Private

private extension AppSettingsViewModel {
    func bind() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateView()
            }
            .store(in: &bag)

        $selectedCurrencyCode
            .dropFirst()
            .sink { [weak self] _ in
                self?.setupView()
            }
            .store(in: &bag)
    }

    func isSavingWalletRequestChange(saveWallet: Bool) {
        Analytics.log(
            .saveUserWalletSwitcherChanged,
            params: [.state: Analytics.ParameterValue.toggleState(for: saveWallet)]
        )

        if saveWallet {
            unlockWithBiometry { [weak self] in
                self?.setSaveWallets($0)
            }
        } else {
            presentSavingWalletDeleteAlert()
        }
    }

    func unlockWithBiometry(completion: @escaping (_ success: Bool) -> Void) {
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { [weak self] result in
            guard let self else { return }

            if case .failure = result {
                updateView()
                completion(false)
            } else {
                userWalletRepository.setSaving(true)
                completion(true)
            }
        }
    }

    func isSavingAccessCodesRequestChange(saveAccessCodes: Bool) {
        Analytics.log(
            .saveAccessCodeSwitcherChanged,
            params: [.state: Analytics.ParameterValue.toggleState(for: saveAccessCodes)]
        )

        if saveAccessCodes {
            setSaveAccessCodes(true)
        } else {
            presentSavingAccessCodesDeleteAlert()
        }
    }

    func setupView() {
        if isBiometryAvailable {
            warningViewModel = nil
        } else {
            warningViewModel = DefaultWarningRowViewModel(
                title: Localization.appSettingsWarningTitle,
                subtitle: Localization.appSettingsWarningSubtitle,
                leftView: .icon(Assets.attention)
            ) { [weak self] in
                self?.openBiometrySettings()
            }
        }

        savingWalletViewModel = DefaultToggleRowViewModel(
            title: Localization.appSettingsSavedWallet,
            isDisabled: !isBiometryAvailable,
            isOn: isSavingWalletBinding()
        )

        savingAccessCodesViewModel = DefaultToggleRowViewModel(
            title: Localization.appSettingsSavedAccessCodes,
            isDisabled: !isBiometryAvailable,
            isOn: isSavingAccessCodesBinding()
        )

        currencySelectionViewModel = DefaultRowViewModel(
            title: Localization.detailsRowTitleCurrency,
            detailsType: .text(selectedCurrencyCode),
            action: coordinator.openCurrencySelection
        )
    }

    func isSavingWalletBinding() -> Binding<Bool> {
        Binding<Bool>(
            root: self,
            default: false,
            get: { $0.isSavingWallet },
            set: { root, newValue in
                root.isSavingWallet = newValue
                root.isSavingWalletRequestChange(saveWallet: newValue)
            }
        )
    }

    func isSavingAccessCodesBinding() -> Binding<Bool> {
        Binding<Bool>(
            root: self,
            default: false,
            get: { $0.isSavingAccessCodes },
            set: { root, newValue in
                root.isSavingAccessCodes = newValue
                root.isSavingAccessCodesRequestChange(saveAccessCodes: newValue)
            }
        )
    }

    func presentSavingWalletDeleteAlert() {
        let okButton = Alert.Button.destructive(Text(Localization.commonDelete)) { [weak self] in
            self?.setSaveWallets(false)
        }
        let cancelButton = Alert.Button.cancel(Text(Localization.commonCancel)) { [weak self] in
            self?.setSaveWallets(true)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: Text(Localization.appSettingsOffSavedWalletAlertMessage),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentSavingAccessCodesDeleteAlert() {
        let okButton = Alert.Button.destructive(Text(Localization.commonDelete)) { [weak self] in
            self?.setSaveAccessCodes(false)
        }

        let cancelButton = Alert.Button.cancel(Text(Localization.commonCancel)) { [weak self] in
            self?.setSaveAccessCodes(true)
        }

        let alert = Alert(
            title: Text(Localization.commonAttention),
            message: Text(Localization.appSettingsOffSavedAccessCodeAlertMessage),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func setSaveWallets(_ saveWallets: Bool) {
        isSavingWallet = saveWallets

        // If saved wallets is turn off we should delete access codes too
        if !saveWallets {
            setSaveAccessCodes(false)
            userWalletRepository.setSaving(false)
        }
    }

    func setSaveAccessCodes(_ saveAccessCodes: Bool) {
        if saveAccessCodes {
            // If savingWallets already on, just update settings
            if isSavingWallet {
                isSavingAccessCodes = true
            } else {
                // Otherwise saving access codes should be on after biometry authorization
                unlockWithBiometry { [weak self] success in
                    self?.setSaveWallets(success)
                    self?.isSavingAccessCodes = success
                }
            }
        } else {
            let accessCodeRepository = AccessCodeRepository()
            accessCodeRepository.clear()

            isSavingAccessCodes = false
        }
    }

    func updateView() {
        isBiometryAvailable = BiometricAuthorizationUtils.getBiometricState() == .available
        setupView()
    }
}

// MARK: - Navigation

extension AppSettingsViewModel {
    func openTokenSynchronization() {
        coordinator.openTokenSynchronization()
    }

    func openResetSavedCards() {
        coordinator.openResetSavedCards()
    }

    func openBiometrySettings() {
        Analytics.log(.buttonEnableBiometricAuthentication)
        coordinator.openAppSettings()
    }
}
