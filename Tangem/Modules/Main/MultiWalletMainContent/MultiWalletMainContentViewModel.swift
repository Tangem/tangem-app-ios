//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemStaking

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoadingTokenList: Bool = true
    @Published var sections: [Section] = []
    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var tokensNotificationInputs: [NotificationViewInput] = []
    @Published var bannerNotificationInputs: [NotificationViewInput] = []

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil

    weak var delegate: MultiWalletMainContentDelegate?

    var footerViewModel: MainFooterViewModel?

    private(set) lazy var bottomSheetFooterViewModel = MainBottomSheetFooterViewModel()

    private(set) var actionButtonsViewModel: ActionButtonsViewModel?

    var isOrganizeTokensVisible: Bool {
        guard canManageTokens else { return false }

        if sections.isEmpty {
            return false
        }

        let numberOfTokens = sections.reduce(0) { $0 + $1.items.count }
        let requiredNumberOfTokens = 2

        return numberOfTokens >= requiredNumberOfTokens
    }

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private let userWalletNotificationManager: NotificationManager
    private let tokensNotificationManager: NotificationManager
    private let bannerNotificationManager: NotificationManager?
    private let tokenSectionsAdapter: TokenSectionsAdapter
    private let tooltipStorageProvider = TooltipStorageProvider()
    private let tokenRouter: SingleTokenRoutable
    private let optionsEditing: OrganizeTokensOptionsEditing
    private let rateAppController: RateAppInteractionController
    private weak var coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable)?

    private var canManageTokens: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    private var cachedTokenItemViewModels: [ObjectIdentifier: TokenItemViewModel] = [:]

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.MultiWalletMainContentViewModel.mappingQueue",
        qos: .userInitiated
    )

    private let isPageSelectedSubject = PassthroughSubject<Bool, Never>()
    private var isUpdating = false

    private var bag = Set<AnyCancellable>()

    init(
        userWalletModel: UserWalletModel,
        userWalletNotificationManager: NotificationManager,
        tokensNotificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        rateAppController: RateAppInteractionController,
        tokenSectionsAdapter: TokenSectionsAdapter,
        tokenRouter: SingleTokenRoutable,
        optionsEditing: OrganizeTokensOptionsEditing,
        coordinator: (MultiWalletMainContentRoutable & ActionButtonsRoutable)?
    ) {
        self.userWalletModel = userWalletModel
        self.userWalletNotificationManager = userWalletNotificationManager
        self.tokensNotificationManager = tokensNotificationManager
        self.bannerNotificationManager = bannerNotificationManager
        self.rateAppController = rateAppController
        self.tokenSectionsAdapter = tokenSectionsAdapter
        self.tokenRouter = tokenRouter
        self.optionsEditing = optionsEditing
        self.coordinator = coordinator

        bind()

        if FeatureProvider.isAvailable(.actionButtons) {
            actionButtonsViewModel = makeActionButtonsViewModel()
        }
    }

    deinit {
        print("MultiWalletMainContentViewModel for \(userWalletModel.name) deinit")
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        if isUpdating {
            return
        }

        isUpdating = true

        if FeatureProvider.isAvailable(.actionButtons) {
            refreshActionButtonsData()
        }

        userWalletModel.userTokensManager.sync { [weak self] in
            self?.isUpdating = false
            completionHandler()
        }
    }

    func deriveEntriesWithoutDerivation() {
        Analytics.log(.mainNoticeScanYourCardTapped)
        isScannerBusy = true
        userWalletModel.userTokensManager.deriveIfNeeded { [weak self] _ in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
            }
        }
    }

    func startBackupProcess() {
        if let input = userWalletModel.backupInput {
            Analytics.log(.mainNoticeBackupWalletTapped)
            coordinator?.openOnboardingModal(with: input)
        }
    }

    func onOpenOrganizeTokensButtonTap() {
        openOrganizeTokens()
    }

    private func refreshActionButtonsData() {
        actionButtonsViewModel?.refresh()
    }

    private func bind() {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let tokenSectionsSourcePublisher = sourcePublisherFactory.makeSourcePublisher(for: userWalletModel)

        let organizedTokensSectionsPublisher = tokenSectionsAdapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: mappingQueue)
            .share(replay: 1)

        let sectionsPublisher = organizedTokensSectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, sections in
                return viewModel.convertToSections(sections)
            }
            .receive(on: DispatchQueue.main)
            .share(replay: 1)

        sectionsPublisher
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)

        organizedTokensSectionsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, sections in
                viewModel.removeOldCachedTokenViewModels(sections)
            }
            .store(in: &bag)

        organizedTokensSectionsPublisher
            .map { $0.flatMap(\.items) }
            .removeDuplicates()
            .map { $0.map(\.walletModelId) }
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, walletModelIds in
                return viewModel.optionsEditing.save(reorderedWalletModelIds: walletModelIds, source: .mainScreen)
            }
            .sink()
            .store(in: &bag)

        userWalletNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        tokensNotificationManager
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.tokensNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        bannerNotificationManager?
            .notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.bannerNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        rateAppController.bind(
            isPageSelectedPublisher: isPageSelectedSubject,
            notificationsPublisher1: $notificationInputs,
            notificationsPublisher2: $tokensNotificationInputs
        )

        subscribeToTokenListSync(with: sectionsPublisher)
    }

    private func convertToSections(
        _ sections: [TokenSectionsAdapter.Section]
    ) -> [Section] {
        let factory = MultiWalletTokenItemsSectionFactory()

        if sections.count == 1, sections[0].items.isEmpty {
            return []
        }

        return sections.enumerated().map { index, section in
            let sectionViewModel = factory.makeSectionViewModel(from: section.model, atIndex: index)
            let itemViewModels = section.items.map { item in
                switch item {
                case .default(let walletModel):
                    // Fetching existing cached View Model for this Wallet Model, if available
                    let cacheKey = ObjectIdentifier(walletModel)
                    if let cachedViewModel = cachedTokenItemViewModels[cacheKey] {
                        return cachedViewModel
                    }
                    let viewModel = makeTokenItemViewModel(from: item, using: factory)
                    cachedTokenItemViewModels[cacheKey] = viewModel
                    return viewModel
                case .withoutDerivation:
                    return makeTokenItemViewModel(from: item, using: factory)
                }
            }

            return Section(model: sectionViewModel, items: itemViewModels)
        }
    }

    private func makeTokenItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        using factory: MultiWalletTokenItemsSectionFactory
    ) -> TokenItemViewModel {
        return factory.makeSectionItemViewModel(
            from: sectionItem,
            contextActionsProvider: self,
            contextActionsDelegate: self,
            tapAction: weakify(self, forFunction: MultiWalletMainContentViewModel.tokenItemTapped(_:))
        )
    }

    private func removeOldCachedTokenViewModels(_ sections: [TokenSectionsAdapter.Section]) {
        let cacheKeys = sections
            .flatMap(\.walletModels)
            .map(ObjectIdentifier.init)
            .toSet()

        cachedTokenItemViewModels = cachedTokenItemViewModels.filter { cacheKeys.contains($0.key) }
    }

    private func subscribeToTokenListSync(with sectionsPublisher: some Publisher<[Section], Never>) {
        let tokenListSyncPublisher = userWalletModel
            .userTokenListManager
            .initializedPublisher
            .filter { $0 }

        let sectionsPublisher = sectionsPublisher
            .replaceEmpty(with: [])

        var tokenListSyncSubscription: AnyCancellable?
        tokenListSyncSubscription = Publishers.Zip(tokenListSyncPublisher, sectionsPublisher)
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.isLoadingTokenList = false
                withExtendedLifetime(tokenListSyncSubscription) {}
            }
    }

    private func tokenItemTapped(_ walletModelId: WalletModelId) {
        guard
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }),
            TokenInteractionAvailabilityProvider(walletModel: walletModel).isTokenDetailsAvailable()
        else {
            return
        }

        coordinator?.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }
}

// MARK: Hide token

private extension MultiWalletMainContentViewModel {
    func hideTokenAction(for tokenItemViewModel: TokenItemViewModel) {
        let tokenItem = tokenItemViewModel.tokenItem

        let alertBuilder = HideTokenAlertBuilder()
        if userWalletModel.userTokensManager.canRemove(tokenItem) {
            error = alertBuilder.hideTokenAlert(tokenItem: tokenItem, hideAction: {
                [weak self] in
                self?.hideToken(tokenItem: tokenItem)
            })
        } else {
            error = alertBuilder.unableToHideTokenAlert(tokenItem: tokenItem)
        }
    }

    func hideToken(tokenItem: TokenItem) {
        userWalletModel.userTokensManager.remove(tokenItem)

        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: tokenItem.currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.main.rawValue,
            ]
        )
    }
}

// MARK: Navigation

extension MultiWalletMainContentViewModel {
    private func openURL(_ url: URL) {
        coordinator?.openInSafari(url: url)
    }

    private func openOrganizeTokens() {
        coordinator?.openOrganizeTokens(for: userWalletModel)
    }

    private func openSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: userWalletModel.emailData,
                    walletModels: userWalletModel.walletModelsManager.walletModels
                ),
            ]
        )

        coordinator?.openMail(
            with: dataCollector,
            emailType: .appFeedback(subject: EmailConfig.default.subject),
            recipient: EmailConfig.default.recipient
        )
    }

    private func openBuy(for walletModel: WalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if FeatureProvider.isAvailable(.onramp) {
            tokenRouter.openOnramp(walletModel: walletModel)
        } else {
            tokenRouter.openBuyCryptoIfPossible(walletModel: walletModel)
        }
    }

    private func openSell(for walletModel: WalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        tokenRouter.openSell(for: walletModel)
    }
}

// MARK: - Notification tap delegate

extension MultiWalletMainContentViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .empty:
            guard let notification = notificationInputs.first(where: { $0.id == id }) else {
                userWalletNotificationManager.dismissNotification(with: id)
                return
            }

            switch notification.settings.event {
            case let userWalletEvent as GeneralNotificationEvent:
                handleUserWalletNotificationTap(event: userWalletEvent, id: id)
            default:
                break
            }

        case .generateAddresses:
            deriveEntriesWithoutDerivation()
        case .backupCard:
            startBackupProcess()
        case .openLink(let url, _):
            openURL(url)
        case .openFeedbackMail:
            rateAppController.openFeedbackMail()
        case .openAppStoreReview:
            rateAppController.openAppStoreReview()
        case .support:
            openSupport()
        default:
            break
        }
    }

    private func handleUserWalletNotificationTap(event: GeneralNotificationEvent, id: NotificationViewId) {
        switch event {
        default:
            assertionFailure("This event shouldn't have tap action on main screen. Event: \(event)")
        }
    }
}

// MARK: - MainViewPage protocol conformance

extension MultiWalletMainContentViewModel: MainViewPage {
    func onPageAppear() {
        isPageSelectedSubject.send(true)
    }

    func onPageDisappear() {
        isPageSelectedSubject.send(false)
    }
}

// MARK: Context actions

extension MultiWalletMainContentViewModel: TokenItemContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection] {
        let actionBuilder = TokenContextActionsBuilder()
        return actionBuilder.buildContextActions(
            tokenItem: tokenItemViewModel.tokenItem,
            walletModelId: tokenItemViewModel.id,
            userWalletModel: userWalletModel,
            canNavigateToMarketsDetails: true,
            canHideToken: canManageTokens
        )
    }
}

extension MultiWalletMainContentViewModel: TokenItemContextActionDelegate {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: TokenItemViewModel) {
        switch action {
        case .hide:
            hideTokenAction(for: tokenItemViewModel)
            return
        case .marketsDetails:
            let tokenItem = tokenItemViewModel.tokenItem
            let analyticsParams: [Analytics.ParameterKey: String] = [
                .source: Analytics.ParameterValue.longTap.rawValue,
                .token: tokenItem.currencySymbol.uppercased(),
                .blockchain: tokenItem.blockchain.displayName,
            ]
            Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
            tokenRouter.openMarketsTokenDetails(for: tokenItem)
            return
        default:
            break
        }

        guard
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == tokenItemViewModel.id })
        else {
            return
        }

        switch action {
        case .buy:
            openBuy(for: walletModel)
        case .send:
            tokenRouter.openSend(walletModel: walletModel)
        case .receive:
            tokenRouter.openReceive(walletModel: walletModel)
        case .sell:
            openSell(for: walletModel)
        case .copyAddress:
            UIPasteboard.general.string = walletModel.defaultAddress
            delegate?.displayAddressCopiedToast()
        case .exchange:
            tokenRouter.openExchange(walletModel: walletModel)
        case .stake:
            tokenRouter.openStaking(walletModel: walletModel)
        case .marketsDetails, .hide:
            return
        }
    }
}

// MARK: - Auxiliary types

extension MultiWalletMainContentViewModel {
    typealias Section = SectionModel<SectionViewModel, TokenItemViewModel>

    struct SectionViewModel: Identifiable {
        let id: AnyHashable
        let title: String?
    }
}

// MARK: - Convenience extensions

private extension TokenSectionsAdapter.Section {
    var walletModels: [WalletModel] {
        return items.compactMap(\.walletModel)
    }
}

// MARK: - Action buttons

private extension MultiWalletMainContentViewModel {
    func makeActionButtonsViewModel() -> ActionButtonsViewModel? {
        guard let coordinator else { return nil }

        return .init(
            coordinator: coordinator,
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            userWalletModel: userWalletModel
        )
    }
}
