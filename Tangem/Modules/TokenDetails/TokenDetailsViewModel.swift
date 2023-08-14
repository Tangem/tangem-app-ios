//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 09/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk
import TangemSwapping

final class TokenDetailsViewModel: SingleTokenBaseViewModel, ObservableObject {
    @Published private var balance: LoadingValue<BalanceInfo> = .loading

    private(set) var balanceWithButtonsModel: BalanceWithButtonsViewModel!
    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: tokenItem)

    private unowned let tokenDetailsCoordinator: TokenDetailsRoutable
    private var bag = Set<AnyCancellable>()
    private var refreshCancellable: AnyCancellable?

    var tokenItem: TokenItem {
        switch amountType {
        case .token(let token):
            return .token(token, blockchain)
        default:
            return .blockchain(blockchain)
        }
    }

    init(
        cardModel: CardViewModel,
        userTokensManager: UserTokensManager,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        coordinator: TokenDetailsRoutable
    ) {
        tokenDetailsCoordinator = coordinator
        super.init(
            userWalletModel: cardModel,
            walletModel: walletModel,
            userTokensManager: userTokensManager,
            exchangeUtility: exchangeUtility,
            coordinator: coordinator
        )
        balanceWithButtonsModel = .init(balanceProvider: self, buttonsProvider: self)

        prepareSelf()
    }

    func onAppear() {
        Analytics.log(.detailsScreenOpened)
        // TODO: Rent warning update will be added in IOS-3847
    }

    func onRefresh(_ done: @escaping () -> Void) {
        Analytics.log(.refreshed)

        refreshCancellable = walletModel
            .update(silent: false)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                AppLog.shared.debug("♻️ Token wallet model loading state changed")
                withAnimation(.default.delay(0.2)) {
                    done()
                }
            } receiveValue: { _ in }

        reloadHistory()
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if userTokensManager.canRemove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    private func showUnableToHideAlert() {
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsUnableHideAlertTitle(currencySymbol),
            message: message,
            primaryButton: .default(Text(Localization.commonOk))
        )
    }

    private func showHideWarningAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsHideAlertTitle(currencySymbol),
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.hideToken()
            },
            secondaryButton: .cancel()
        )
    }

    private func hideToken() {
        Analytics.log(event: .buttonRemoveToken, params: [Analytics.ParameterKey.token: currencySymbol])

        userTokensManager.remove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        bind()
    }

    private func bind() {
        walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newState in
                AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
                self?.updateBalance(walletModelState: newState)
            }
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created, .loading:
            balance = .loading
        case .idle:
            balance = .loaded(.init(
                balance: walletModel.getDecimalBalance(for: amountType) ?? 0,
                currencyId: walletModel.tokenItem.currencyId,
                currencyCode: currencySymbol
            ))
        case .noAccount(let message), .failed(let message):
            balance = .failedToLoad(error: message)
        case .noDerivation:
            // User can't reach this screen without derived keys
            balance = .failedToLoad(error: "")
        }
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func dismiss() {
        tokenDetailsCoordinator.dismiss()
    }
}

extension TokenDetailsViewModel: BalanceProvider {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { $balance.eraseToAnyPublisher() }
}
