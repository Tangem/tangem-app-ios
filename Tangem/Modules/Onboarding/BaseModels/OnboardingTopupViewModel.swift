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
        if let wallet = userWalletModel?.walletModelsManager.walletModels.first?.wallet {
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
        userWalletModel?.walletModelsManager.walletModels.first?.shareAddressString(for: 0) ?? ""
    }

    private var walletAddress: String {
        userWalletModel?.walletModelsManager.walletModels.first?.displayAddress(for: 0) ?? ""
    }

    private var qrNoticeMessage: String {
        userWalletModel?.walletModelsManager.walletModels.first?.qrReceiveMessage ?? ""
    }

    private var refreshButtonDispatchWork: DispatchWorkItem?

    func updateCardBalance(shouldGoToNextStep: Bool = true) {
        guard
            let walletModel = userWalletModel?.walletModelsManager.walletModels.first,
            walletModelUpdateCancellable == nil
        else { return }

        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.update(silent: false)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModelState in
                viewModel.updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message, _):
                    AppLog.shared.debug(message)
                    fallthrough
                case .idle:
                    if shouldGoToNextStep,
                       !walletModel.isEmptyIncludingPendingIncomingTxs,
                       !walletModel.isZeroAmount {
                        if let userWalletId = viewModel.userWalletModel?.userWalletId {
                            Analytics.logTopUpIfNeeded(balance: walletModel.fiatValue ?? 0, for: userWalletId)
                        }
                        viewModel.goToNextStep()
                        viewModel.walletModelUpdateCancellable = nil
                        return
                    }

                    viewModel.resetRefreshButtonState()
                case .failed(let error):
                    viewModel.resetRefreshButtonState()

                    // Need check is display alert yet, because not to present an error if it is already shown
                    guard viewModel.alert == nil else {
                        return
                    }

                    viewModel.alert = error.alertBinder
                case .loading, .created, .noDerivation:
                    return
                }
                viewModel.walletModelUpdateCancellable = nil
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
    func openQR() {
        Analytics.log(.onboardingButtonShowTheWalletAddress)

        coordinator?.openQR(shareAddress: shareAddress, address: walletAddress, qrNotice: qrNoticeMessage)
    }

    func openBuyCrypto() {
        guard let url = buyCryptoURL else { return }

        Analytics.log(.buttonBuyCrypto)
        coordinator?.openCryptoShop(at: url) { [weak self] in
            self?.updateCardBalance()
        }
    }
}
