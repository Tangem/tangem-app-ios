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

    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = ""
    @Published var isBalanceRefresherVisible: Bool = false

    var walletModelUpdateCancellable: AnyCancellable?

    var buyCryptoURL: URL? {
        if let wallet = cardModel?.walletModels.first?.wallet {
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
        cardModel?.walletModels.first?.qrReceiveMessage ?? ""
    }

    private var refreshButtonDispatchWork: DispatchWorkItem?

    func updateCardBalance(shouldGoToNextStep: Bool = true) {
        guard
            let walletModel = cardModel?.walletModels.first,
            walletModelUpdateCancellable == nil
        else { return }

        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.update(silent: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModelState in
                guard let self = self else { return }

                updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message):
                    AppLog.shared.debug(message)
                    fallthrough
                case .idle:
                    if shouldGoToNextStep,
                       !walletModel.isEmptyIncludingPendingIncomingTxs,
                       !walletModel.isZeroAmount {
                        Analytics.logTopUpIfNeeded(balance: walletModel.fiatValue?.rawValue ?? 0)
                        goToNextStep()
                        walletModelUpdateCancellable = nil
                        return
                    }

                    resetRefreshButtonState()
                case .failed(let error):
                    resetRefreshButtonState()

                    // Need check is display alert yet, because not to present an error if it is already shown
                    guard alert == nil else {
                        return
                    }

                    alert = error.alertBinder
                case .loading, .created, .noDerivation:
                    return
                }
                walletModelUpdateCancellable = nil
            }
    }

    func updateCardBalanceText(for model: WalletModel) {
        if case .failed = model.state {
            cardBalance = "–"
            return
        }

        if model.wallet.amounts.isEmpty {
            let zeroAmount = Amount(with: model.wallet.blockchain, type: .coin, value: 0)
            cardBalance = zeroAmount.string(with: 8)
        } else {
            cardBalance = model.balance
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
