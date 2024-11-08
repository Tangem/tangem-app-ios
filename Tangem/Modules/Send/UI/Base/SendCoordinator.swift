//
//  SendCoordinator.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemExpress

class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator?
    @Published var onrampProvidersCoordinator: OnrampProvidersCoordinator?
    @Published var onrampWebViewCoordinator: OnrampRedirectingCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var expressApproveViewModel: ExpressApproveViewModel?
    @Published var onrampCountryDetectionViewModel: OnrampCountryDetectionViewModel?

    @Published var onrampSettingsViewModel: OnrampSettingsViewModel?
    @Published var onrampCountrySelectorViewModel: OnrampCountrySelectorViewModel?
    @Published var onrampCurrencySelectorViewModel: OnrampCurrencySelectorViewModel?

    required init(
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let factory = SendFlowFactory(userWalletModel: options.userWalletModel, walletModel: options.walletModel)

        switch options.type {
        case .send:
            rootViewModel = factory.makeSendViewModel(router: self)
        case .sell(let parameters):
            rootViewModel = factory.makeSellViewModel(sellParameters: parameters, router: self)
        case .staking(let manager):
            rootViewModel = factory.makeStakingViewModel(manager: manager, router: self)
        case .unstaking(let manager, let action) where StakingFeatureProvider.isPartialUnstakeAvailable:
            rootViewModel = factory.makeUnstakingViewModel(manager: manager, action: action, router: self)
        case .unstaking(let manager, let action):
            rootViewModel = factory.makeStakingSingleActionViewModel(manager: manager, action: action, router: self)
        case .restaking(let manager, let action):
            rootViewModel = factory.makeRestakingViewModel(manager: manager, action: action, router: self)
        case .stakingSingleAction(let manager, let action):
            rootViewModel = factory.makeStakingSingleActionViewModel(manager: manager, action: action, router: self)
        case .onramp:
            rootViewModel = factory.makeOnrampViewModel(router: self)
        }
    }
}

// MARK: - Options

extension SendCoordinator {
    struct Options {
        let walletModel: WalletModel
        let userWalletModel: UserWalletModel
        let type: SendType
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func dismiss() {
        dismiss(with: nil)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }

    func openFeeExplanation(url: URL) {
        safariManager.openURL(url)
    }

    func openExplorer(url: URL) {
        safariManager.openURL(url)
    }

    func openShareSheet(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {
        Analytics.log(.sendButtonQRCode)

        let qrScanViewCoordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        let text = Localization.sendQrcodeScanInfo(networkName)
        let options = QRScanViewCoordinator.Options(code: codeBinding, text: text)
        qrScanViewCoordinator.start(with: options)

        self.qrScanViewCoordinator = qrScanViewCoordinator
    }

    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {
        dismiss(with: (walletModel, userWalletModel))
    }

    func openApproveView(settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput) {
        expressApproveViewModel = .init(
            settings: settings,
            feeFormatter: CommonFeeFormatter(
                balanceFormatter: .init(),
                balanceConverter: .init()
            ),
            logger: AppLog.shared,
            approveViewModelInput: approveViewModelInput,
            coordinator: self
        )
    }
}

// MARK: - ExpressApproveRoutable

extension SendCoordinator: OnrampRoutable {
    func openOnrampCountryDetection(country: OnrampCountry, repository: OnrampRepository) {
        onrampCountryDetectionViewModel = OnrampCountryDetectionViewModel(
            country: country,
            repository: repository,
            coordinator: self
        )
    }

    func openOnrampCountrySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {
        onrampCountrySelectorViewModel = OnrampCountrySelectorViewModel(
            repository: repository,
            dataRepository: dataRepository,
            coordinator: self
        )
    }

    func openOnrampSettings(repository: any OnrampRepository) {
        onrampSettingsViewModel = OnrampSettingsViewModel(
            repository: repository,
            coordinator: self
        )
    }

    func openOnrampCurrencySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository) {
        onrampCurrencySelectorViewModel = OnrampCurrencySelectorViewModel(
            repository: repository,
            dataRepository: dataRepository,
            coordinator: self
        )
    }

    func openOnrampProviders(providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder) {
        let coordinator = OnrampProvidersCoordinator(
            onrampProvidersBuilder: providersBuilder,
            onrampPaymentMethodsBuilder: paymentMethodsBuilder,
            dismissAction: { [weak self] in
                self?.onrampProvidersCoordinator = nil
            }, popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        onrampProvidersCoordinator = coordinator
    }

    func openOnrampRedirecting(tokenItem: TokenItem, provider: OnrampProvider, onrampManager: OnrampManager) {
        let coordinator = OnrampRedirectingCoordinator(dismissAction: { [weak self] in
            self?.onrampWebViewCoordinator = nil
        }, popToRootAction: popToRootAction)

        coordinator.start(with: .init(tokenItem: tokenItem, provider: provider, onrampManager: onrampManager))

        onrampWebViewCoordinator = coordinator
    }
}

// MARK: - ExpressApproveRoutable

extension SendCoordinator: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        expressApproveViewModel = nil
    }

    func userDidCancel() {
        expressApproveViewModel = nil
    }
}

// MARK: - OnrampCountryDetectionRoutable

extension SendCoordinator: OnrampCountryDetectionRoutable {
    func openChangeCountry() {
        onrampCountryDetectionViewModel = nil
        rootViewModel?.openOnrampCountrySelectorView()
    }

    func dismissConfirmCountryView() {
        onrampCountryDetectionViewModel = nil
    }
}

// MARK: - OnrampCountrySelectorRoutable

extension SendCoordinator: OnrampCountrySelectorRoutable {
    func dismissCountrySelector() {
        onrampCountrySelectorViewModel = nil
    }
}

// MARK: - OnrampSettingsRoutable

extension SendCoordinator: OnrampSettingsRoutable {
    func openOnrampCountrySelector() {
        rootViewModel?.openOnrampCountrySelectorView()
    }
}

// MARK: - OnrampCurrencySelectorRoutable

extension SendCoordinator: OnrampCurrencySelectorRoutable {
    func dismissCurrencySelector() {
        onrampCurrencySelectorViewModel = nil
    }
}

// MARK: - OnrampAmountRoutable

extension SendCoordinator: OnrampAmountRoutable {
    func openOnrampCurrencySelector() {
        rootViewModel?.openOnrampCurrencySelectorView()
    }
}
