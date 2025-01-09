//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class SingleWalletMainContentViewModel: SingleTokenBaseViewModel, ObservableObject {
    // MARK: - ViewState

    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var walletPromoBannerViewModel: WalletPromoBannerViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    // MARK: - Dependencies

    private let userWalletNotificationManager: NotificationManager
    private let rateAppController: RateAppInteractionController

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()

    private var updateSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    private weak var delegate: SingleWalletMainContentDelegate?

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        userWalletNotificationManager: NotificationManager,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        tokenNotificationManager: NotificationManager,
        rateAppController: RateAppInteractionController,
        tokenRouter: SingleTokenRoutable,
        delegate: SingleWalletMainContentDelegate?
    ) {
        self.userWalletNotificationManager = userWalletNotificationManager
        self.rateAppController = rateAppController
        self.delegate = delegate

        if WalletPromoBannerUtil().shouldShowBanner() {
            walletPromoBannerViewModel = .init(
                currencySymbol: walletModel.tokenItem.currencySymbol,
                tokenRouter: tokenRouter
            )
        }

        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: tokenNotificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            tokenRouter: tokenRouter
        )

        bind()
    }

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        delegate?.present(actionSheet: actionSheet)
    }

    override func copyDefaultAddress() {
        super.copyDefaultAddress()
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.main.rawValue,
        ])
        delegate?.displayAddressCopiedToast()
    }

    override func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .openFeedbackMail:
            rateAppController.openFeedbackMail()
        case .openAppStoreReview:
            rateAppController.openAppStoreReview()
        default:
            super.didTapNotification(with: id, action: action)
        }
    }

    override func openMarketsTokenDetails() {
        guard isMarketsDetailsAvailable else {
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.main.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
        super.openMarketsTokenDetails()
    }

    private func bind() {
        userWalletNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        rateAppController.bind(
            isPageSelectedPublisher: isPageSelectedSubject,
            notificationsPublisher: $notificationInputs
        )
    }
}

// MARK: - MainViewPage protocol conformance

extension SingleWalletMainContentViewModel: MainViewPage {
    func onPageAppear() {
        isPageSelectedSubject.send(true)
    }

    func onPageDisappear() {
        isPageSelectedSubject.send(false)
    }
}
