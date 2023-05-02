//
//  OnboardingTopupViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 15.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class OnboardingTopupViewModel<Step: OnboardingStep, Coordinator: OnboardingTopupRoutable>: OnboardingViewModel<Step, Coordinator> {
    @Injected(\.exchangeService) var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.analyticsContext) var analyticsContext: AnalyticsContext

    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = ""
    @Published var isBalanceRefresherVisible: Bool = false

    var walletModelUpdateCancellable: AnyCancellable?

    var buyCryptoURL: URL? {
        if let wallet = cardModel?.wallets.first {
            return exchangeService.getBuyUrl(
                currencySymbol: wallet.blockchain.currencySymbol,
                amountType: .coin,
                blockchain: wallet.blockchain,
                walletAddress: wallet.address
            )
        }

        return nil
    }

    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }

    private var shareAddress: String {
        cardModel?.walletModels.first?.shareAddressString(for: 0) ?? ""
    }

    private var walletAddress: String {
        cardModel?.walletModels.first?.displayAddress(for: 0) ?? ""
    }

    private var qrNoticeMessage: String {
        cardModel?.walletModels.first?.getQRReceiveMessage() ?? ""
    }

    private var refreshButtonDispatchWork: DispatchWorkItem?

    func updateCardBalance(for type: Amount.AmountType = .coin, shouldGoToNextStep: Bool = true) {
        guard
            let walletModel = cardModel?.walletModels.first,
            walletModelUpdateCancellable == nil
        else { return }

        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] walletModelState in
                guard let self = self else { return }

                self.updateCardBalanceText(for: walletModel, type: type)
                switch walletModelState {
                case .noAccount(let message):
                    AppLog.shared.debug(message)
                    fallthrough
                case .idle:
                    if shouldGoToNextStep,
                       !walletModel.isEmptyIncludingPendingIncomingTxs,
                       !(walletModel.wallet.amounts[type]?.isZero ?? true) {
                        Analytics.logTopUpIfNeeded(balance: walletModel.totalBalance)
                        self.goToNextStep()
                        self.walletModelUpdateCancellable = nil
                        return
                    }

                    self.resetRefreshButtonState()
                case .failed(let error):
                    self.resetRefreshButtonState()

                    // Need check is display alert yet, because not to present an error if it is already shown
                    guard self.alert == nil else {
                        return
                    }

                    self.alert = error.alertBinder
                case .loading, .created, .noDerivation:
                    return
                }
                self.walletModelUpdateCancellable = nil
            }
        walletModel.update(silent: false)
    }

    func updateCardBalanceText(for model: WalletModel, type: Amount.AmountType = .coin) {
        if case .failed = model.state {
            cardBalance = "–"
            return
        }

        if model.wallet.amounts.isEmpty {
            let zeroAmount = type.token.map { Amount(with: $0, value: 0) } ??
                Amount(with: model.wallet.blockchain, type: type, value: 0)

            cardBalance = zeroAmount.string(with: 8)
        } else {
            cardBalance = model.getBalance(for: type)
        }
    }

    func resetRefreshButtonState() {
        withAnimation {
            self.refreshButtonState = .refreshButton
        }
    }
}

// MARK: - Navigation

extension OnboardingTopupViewModel {
    func openCryptoShopIfPossible() {
        Analytics.log(.buttonBuyCrypto)

        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator.openBankWarning {
                self.openBuyCrypto()
            } declineCallback: {
                self.openP2PTutorial()
            }
        } else {
            openBuyCrypto()
        }
    }

    func openQR() {
        Analytics.log(.onboardingButtonShowTheWalletAddress)

        coordinator.openQR(shareAddress: shareAddress, address: walletAddress, qrNotice: qrNoticeMessage)
    }

    private func openBuyCrypto() {
        guard let url = buyCryptoURL else { return }

        coordinator.openCryptoShop(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
            self?.updateCardBalance()
        }
    }

    private func openP2PTutorial() {
        coordinator.openP2PTutorial()
    }
}
