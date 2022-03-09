//
//  Assembly+App.swift
//  Tangem
//
//  Created by Andrew Son on 04/08/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

extension Assembly {
    // MARK: - Onboarding
    func getLaunchOnboardingViewModel() -> OnboardingBaseViewModel {
        let key = "launch_onboarding_screen"
        if let restored: OnboardingBaseViewModel = get(key: key) {
            return restored
        }
        
        let vm = OnboardingBaseViewModel()
        initialize(vm, with: key, isResetable: false)
        vm.userPrefsService = services.userPrefsService
        
        return vm
    }
    func getLetsStartOnboardingViewModel() -> WelcomeOnboardingViewModel? {
        if let restored: WelcomeOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    func getLetsStartOnboardingViewModel(with callback: @escaping (OnboardingInput) -> Void) -> WelcomeOnboardingViewModel {
        if let restored: WelcomeOnboardingViewModel = get() {
            restored.successCallback = callback
            return restored
        }
        
        let vm = WelcomeOnboardingViewModel(successCallback: callback)
        initialize(vm, isResetable: false)
        vm.cardsRepository = services.cardsRepository
        vm.stepsSetupService = services.onboardingStepsSetupService
        vm.userPrefsService = services.userPrefsService
        vm.failedCardScanTracker = services.failedCardScanTracker
        vm.backupService = services.backupService
        return vm
    }
    
    func getCardOnboardingViewModel() -> OnboardingBaseViewModel {
        if let restored: OnboardingBaseViewModel = get() {
            return restored
        }
        
        return getLaunchOnboardingViewModel()
    }
    
    
    @discardableResult
    func makeCardOnboardingViewModel(with input: OnboardingInput) -> OnboardingBaseViewModel {
        let vm = OnboardingBaseViewModel(input: input)
        initialize(vm, isResetable: false)
        
        switch input.steps {
        case .singleWallet:
            makeNoteOnboardingViewModel(with: input)
        case .twins:
            makeTwinOnboardingViewModel(with: input)
        case .wallet:
            makeWalletOnboardingViewModel(with: input)
        }
        
        return vm
    }
    
    func getOnboardingViewModel() -> SingleCardOnboardingViewModel {
        if let restored: SingleCardOnboardingViewModel = get() {
            return restored
        }
        
        return makeNoteOnboardingViewModel(with: previewNoteCardOnboardingInput)
    }
    
    @discardableResult
    func makeNoteOnboardingViewModel(with input: OnboardingInput) -> SingleCardOnboardingViewModel {
        let vm = SingleCardOnboardingViewModel(exchangeService: services.exchangeService, input: input)
        initialize(vm, isResetable: false)
        vm.cardsRepository = services.cardsRepository
        vm.stepsSetupService = services.onboardingStepsSetupService
        vm.userPrefsService = services.userPrefsService
        vm.exchangeService = services.exchangeService
        vm.tokensRepo = services.tokenItemsRepository
        return vm
    }
    
    func getTwinsOnboardingViewModel() -> TwinsOnboardingViewModel {
        if let restored: TwinsOnboardingViewModel = get() {
            return restored
        }
        
        return makeTwinOnboardingViewModel(with: previewTwinOnboardingInput)
    }
    
    @discardableResult
    func makeTwinOnboardingViewModel(with input: OnboardingInput) -> TwinsOnboardingViewModel {
        let vm = TwinsOnboardingViewModel(imageLoaderService: services.imageLoaderService,
                                          twinsService: services.twinsWalletCreationService,
                                          exchangeService: services.exchangeService,
                                          input: input)
        initialize(vm, isResetable: false)
        vm.userPrefsService = services.userPrefsService
        
        return vm
    }
    
    func getWalletOnboardingViewModel() -> WalletOnboardingViewModel {
        if let restored: WalletOnboardingViewModel = get() {
            return restored
        }
        
        return makeWalletOnboardingViewModel(with: previewWalletOnboardingInput)
    }
    
    //temp
    func getTwinOnboardingViewModel() -> TwinsOnboardingViewModel? {
        if let restored: TwinsOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    //temp
    func getWalletOnboardingViewModel() -> WalletOnboardingViewModel? {
        if let restored: WalletOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    @discardableResult
    func makeWalletOnboardingViewModel(with input: OnboardingInput) -> WalletOnboardingViewModel {
        let sdk = services.tangemSdk
        let vm = WalletOnboardingViewModel(input: input,
                                           backupService: services.backupService,
                                           tangemSdk: sdk,
                                           tokensRepo: services.tokenItemsRepository,
                                           imageLoaderService: services.imageLoaderService)
        
        initialize(vm, isResetable: false)
        vm.userPrefsService = services.userPrefsService
        
        return vm
    }
    
    func makeWelcomeStoriesModel() -> StoriesViewModel {
        if let restored: StoriesViewModel = get() {
            return restored
        }
        
        let vm = StoriesViewModel()
        initialize(vm, isResetable: false)
        vm.userPrefsService = services.userPrefsService
        return vm
    }

    
    //    func makeReadViewModel() -> ReadViewModel {
    //        if let restored: ReadViewModel = get() {
    //            return restored
    //        }
    //
    //        let vm =  ReadViewModel()
    //        initialize(vm, isResetable: false)
    //        vm.failedCardScanTracker = services.failedCardScanTracker
    //        vm.userPrefsService = services.userPrefsService
    //        vm.cardsRepository = services.cardsRepository
    //        return vm
    //    }
    
    // MARK: - Main view model
    func makeMainViewModel() -> MainViewModel {
        if let restored: MainViewModel = get() {
            return restored
        }
        
        let vm =  MainViewModel()
        initialize(vm, isResetable: false)
        vm.cardsRepository = services.cardsRepository
        vm.exchangeService = services.exchangeService
        vm.userPrefsService = services.userPrefsService
        vm.warningsManager = services.warningsService
        vm.rateAppController = services.rateAppService
        vm.cardOnboardingStepSetupService = services.onboardingStepsSetupService
        
        vm.state = services.cardsRepository.lastScanResult
        
        vm.negativeFeedbackDataCollector = services.negativeFeedbackDataCollector
        vm.failedCardScanTracker = services.failedCardScanTracker
        
        return vm
    }
    
    func makeTokenDetailsViewModel( blockchain: Blockchain, amountType: Amount.AmountType = .coin) -> TokenDetailsViewModel {
        if let restored: TokenDetailsViewModel = get() {
            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
                //   restored.card = cardModel
            }
            return restored
        }
        
        let vm =  TokenDetailsViewModel(blockchain: blockchain, amountType: amountType)
        initialize(vm)
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.card = cardModel
        }
        vm.exchangeService = services.exchangeService
        return vm
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.featuresService = services.featuresService
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        vm.warningsConfigurator = services.warningsService
        vm.warningsAppendor = services.warningsService
        vm.tokenItemsRepository = services.tokenItemsRepository
        vm.userPrefsService = services.userPrefsService
        vm.imageLoaderService = services.imageLoaderService
        vm.updateState()
        return vm
    }
    
    func makeDisclaimerViewModel(with state: DeprecatedDisclaimerViewModel.State = .read) -> DeprecatedDisclaimerViewModel {
        // This is needed to prevent updating state of views that already in view hierarchy. Creating new model for each state
        // not so good solution, but this crucial when creating Navigation link without condition closures and Navigation link
        // recreates every redraw process. If you don't want to reinstantiate Navigation link, then functionality of pop to
        // specific View in navigation stack will be lost or push navigation animation will be disabled due to use of
        // StackNavigationViewStyle for NavigationView. Probably this is bug in current Apple realisation of NavigationView
        // and NavigationLinks - all navigation logic tightly coupled with View and redraw process.
        
        let name = String(describing: DeprecatedDisclaimerViewModel.self) + "_\(state)"
        let isTwin = services.cardsRepository.lastScanResult.cardModel?.isTwinCard ?? false
        if let vm: DeprecatedDisclaimerViewModel = get(key: name) {
            vm.isTwinCard = isTwin
            return vm
        }
        
        let vm = DeprecatedDisclaimerViewModel()
        vm.state = state
        vm.isTwinCard = isTwin
        vm.userPrefsService = services.userPrefsService
        initialize(vm, with: name, isResetable: false)
        return vm
    }
    
    // MARK: - Details
    
    func makeDetailsViewModel() -> DetailsViewModel {
        
        if let restored: DetailsViewModel = get() {
            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
                restored.cardModel = cardModel
            }
            return restored
        }
        
        let vm =  DetailsViewModel()
        initialize(vm)
        
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.cardModel = cardModel
            vm.dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel)
        }
        vm.cardsRepository = services.cardsRepository
        vm.ratesService = services.ratesService
        vm.onboardingStepsSetupService = services.onboardingStepsSetupService
        return vm
    }
    
    func makeSecurityManagementViewModel(with card: CardViewModel) -> SecurityManagementViewModel {
        if let restored: SecurityManagementViewModel = get() {
            return restored
        }
        
        let vm = SecurityManagementViewModel()
        initialize(vm)
        vm.cardViewModel = card
        return vm
    }
    
    func makeCurrencySelectViewModel() -> CurrencySelectViewModel {
        if let restored: CurrencySelectViewModel = get() {
            return restored
        }
        
        let vm =  CurrencySelectViewModel()
        initialize(vm)
        vm.ratesService = services.ratesService
        return vm
    }
    
    func makeTokenListViewModel(mode: TokenListViewModel.Mode) -> TokenListViewModel {
        if let restored: TokenListViewModel = get(key: mode.id) {
            return restored
        }
        
        let vm = TokenListViewModel(mode: mode)
        initialize(vm)
        return vm
    }
    
    func makeSendViewModel(with amount: Amount, blockchain: Blockchain, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm: SendViewModel = SendViewModel(amountToSend: amount,
                                              blockchain: blockchain,
                                              cardViewModel: card,
                                              warningsManager: services.warningsService)
        
        if services.featuresService.isPayIdEnabled, let payIdService = PayIDService.make(from: blockchain) {
            vm.payIDService = payIdService
        }
        
        prepareSendViewModel(vm)
        return vm
    }
    
    func makeSellCryptoSendViewModel(with amount: Amount, destination: String, blockchain: Blockchain, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(amountToSend: amount,
                               destination: destination,
                               blockchain: blockchain,
                               cardViewModel: card,
                               warningsManager: services.warningsService)
        prepareSendViewModel(vm)
        return vm
    }
    
    func makePushViewModel(for tx: BlockchainSdk.Transaction, blockchain: Blockchain, card: CardViewModel) -> PushTxViewModel {
        if let restored: PushTxViewModel = get() {
            restored.transaction = tx
            return restored
        }
        
        let vm = PushTxViewModel(transaction: tx, blockchain: blockchain, cardViewModel: card, signer: services.signer, ratesService: services.ratesService)
        initialize(vm)
        vm.emailDataCollector = PushScreenDataCollector(pushTxViewModel: vm)
        return vm
    }
    
   
    func makeWalletConnectViewModel(cardModel: CardViewModel) -> WalletConnectViewModel {
        let vm = WalletConnectViewModel(cardModel: cardModel)
        initialize(vm)
        vm.walletConnectController = services.walletConnectService
        return vm
    }
    
    func makeShopViewModel() -> ShopViewModel {
        if let restored: ShopViewModel = get() {
            return restored
        }
        
        let vm = ShopViewModel()
        initialize(vm)
        vm.shopifyService = services.shopifyService
        return vm
    }
    
    func makeAllWalletModels(from cardInfo: CardInfo) -> [WalletModel] {
        let walletManagerFactory = WalletManagerFactory(config: services.keysManager.blockchainConfig)
        let assembly = WalletManagerAssembly(factory: walletManagerFactory,
                                             tokenItemsRepository: services.tokenItemsRepository)
        let walletManagers = assembly.makeAllWalletManagers(for: cardInfo)
        return makeWalletModels(walletManagers: walletManagers, cardInfo: cardInfo)
    }
    
    func makeWalletModels(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletModel] {
        let walletManagerFactory = WalletManagerFactory(config: services.keysManager.blockchainConfig)
        let assembly = WalletManagerAssembly(factory: walletManagerFactory,
                                             tokenItemsRepository: services.tokenItemsRepository)
        let walletManagers = assembly.makeWalletManagers(from: cardInfo, blockchains: blockchains)
        return makeWalletModels(walletManagers: walletManagers, cardInfo: cardInfo)
    }
    
    func makeWalletModels(from cardDto: SavedCard, blockchains: [Blockchain]) -> [WalletModel] {
        let walletManagerFactory = WalletManagerFactory(config: services.keysManager.blockchainConfig)
        let assembly = WalletManagerAssembly(factory: walletManagerFactory,
                                             tokenItemsRepository: services.tokenItemsRepository)
        let walletManagers = assembly.makeWalletManagers(from: cardDto, blockchains: blockchains)
        return makeWalletModels(walletManagers: walletManagers, cardInfo: nil)
    }
    
    //Make walletModel from walletManager
    private func makeWalletModels(walletManagers: [WalletManager], cardInfo: CardInfo?) -> [WalletModel] {
        let items = SupportedTokenItems()
        return walletManagers.map { manager -> WalletModel in
            var demoBalance: Decimal? = nil
            if let card = cardInfo?.card, card.isDemoCard,
               let balance = items.predefinedDemoBalances[manager.wallet.blockchain] {
                demoBalance = balance
            }
            
            let model = WalletModel(walletManager: manager,
                                    signer: services.signer,
                                    defaultToken: cardInfo?.defaultToken,
                                    defaultBlockchain: cardInfo?.defaultBlockchain,
                                    demoBalance: demoBalance)
            model.tokenItemsRepository = services.tokenItemsRepository
            model.ratesService = services.ratesService
            return model
        }
    }
    
    private func initialize<V: ViewModel>(_ vm: V, isResetable: Bool = true) {
        vm.navigation = services.navigationCoordinator
        vm.assembly = self
        store(vm, isResetable: isResetable)
    }
    
    private func initialize<V: ViewModel>(_ vm: V, with key: String, isResetable: Bool) {
        vm.navigation = services.navigationCoordinator
        vm.assembly = self
        store(vm, with: key, isResetable: isResetable)
    }
    
    private func get<T>(key: String) -> T? {
        let val = (modelsStorage[key] ?? persistenceStorage[key]) as? ViewModelNavigatable
        val?.navigation = services.navigationCoordinator
        return val as? T
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
    public func reset() {
        modelsStorage.removeAll()
    }
    
    private func prepareSendViewModel(_ vm: SendViewModel) {
        initialize(vm)
        vm.ratesService = services.ratesService
        vm.featuresService = services.featuresService
        vm.emailDataCollector = SendScreenDataCollector(sendViewModel: vm)
    }
}
