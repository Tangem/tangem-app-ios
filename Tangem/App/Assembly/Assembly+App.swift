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
                                           tokensRepo: services.tokenItemsRepository)
        
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
    
    ///Make wallets for blockchains
    func makeWallets(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletModel] {
        let walletManagers = makeWalletManagers(from: cardInfo, blockchains: blockchains)
        return makeWalletModels(walletManagers: walletManagers, cardToken: cardInfo.defaultToken)
    }
    
    func makeWallets(from cardDto: SavedCard, blockchains: [Blockchain]) -> [WalletModel] {
        let walletManagers = makeWalletManagers(from: cardDto, blockchains: blockchains)
        return makeWalletModels(walletManagers: walletManagers, cardToken: nil)
    }
    
    ///Load all possible wallets for card
    func loadWallets(from cardInfo: CardInfo) -> [WalletModel] {
        var walletManagers: [WalletManager] = .init()
        
        //If this card is Twin, return twinWallet
        if cardInfo.card.isTwinCard,
           let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey,
           let publicKey = cardInfo.card.wallets.first?.publicKey,
           let twinWalletManager = try? services.walletManagerFactory.makeTwinWalletManager(from: cardInfo.card.cardId,
                                                                                            walletPublicKey: publicKey,
                                                                                            pairKey: savedPairKey,
                                                                                            isTestnet: false) {  //TODO: Do we actually need testnet for twins?
            walletManagers.append(twinWalletManager)
        } else {
            //If this card supports multiwallet feature, load all saved tokens from persistent storage
            let tokenItems = services.tokenItemsRepository.getItems(for: cardInfo.card.cardId)
            if cardInfo.isMultiWallet, !tokenItems.isEmpty {
                
                //Load erc20 tokens if exists
                let tokens = tokenItems.compactMap { $0.token }
                if let secpWallet = cardInfo.card.wallets.first(where: { $0.curve == .secp256k1 }),
                   let tokenManagers = try? services.walletManagerFactory.makeWalletManagers(for: cardInfo.card.cardId,
                                                                                                wallet: secpWallet,
                                                                                                and: tokens) {
                    walletManagers.append(contentsOf: tokenManagers)
                }
                
                //Load blockchains if exists
                let existingBlockchains = walletManagers.map { $0.wallet.blockchain }
                let additionalBlockchains = tokenItems.compactMap ({ $0.blockchain }).filter{ !existingBlockchains.contains($0) }
                let additionalWalletManagers = makeWalletManagers(from: cardInfo, blockchains: additionalBlockchains)
                walletManagers.append(contentsOf: additionalWalletManagers)
            }
            
            //Try found default card wallet
            if let nativeWalletManager = makeNativeWalletManager(from: cardInfo), !walletManagers.contains(where: { $0.wallet.blockchain == nativeWalletManager.wallet.blockchain }) {
                walletManagers.append(nativeWalletManager)
            }
        }
        return makeWalletModels(walletManagers: walletManagers, cardToken: cardInfo.defaultToken)
    }
    
    //Make walletModel from walletManager
    private func makeWalletModels(walletManagers: [WalletManager], cardToken: BlockchainSdk.Token?) -> [WalletModel] {
        return walletManagers.map { manager -> WalletModel in
            let model = WalletModel(walletManager: manager, defaultToken: cardToken)
            model.tokenItemsRepository = services.tokenItemsRepository
            model.ratesService = services.ratesService
            return model
        }
    }
    
    /// Try to load native walletmanager from card
    private func makeNativeWalletManager(from cardInfo: CardInfo) -> WalletManager? {
        if let defaultBlockchain = cardInfo.defaultBlockchain,
           let cardWalletManager = makeWalletManagers(from: cardInfo, blockchains: [defaultBlockchain]).first {
            
            if let defaultToken = cardInfo.defaultToken {
                _ = cardWalletManager.addToken(defaultToken)
            }
            
            return cardWalletManager
            
        }
        
        return nil
    }
    
    ///Try to make WalletManagers for blockchains with suitable wallet
    private func makeWalletManagers(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletManager] {
        var walletManagers = [WalletManager]()
        
        for blockchain in blockchains {
            if let wallet = cardInfo.card.wallets.first(where: { $0.curve == blockchain.curve }),
               let wm = try? services.walletManagerFactory.makeWalletManager(from: cardInfo.card.cardId,
                                                                             wallet: wallet,
                                                                             blockchain: blockchain) {
                walletManagers.append(wm)
            }
        }
        
        return walletManagers
    }
    
    private func makeWalletManagers(from cardDto: SavedCard, blockchains: [Blockchain]) -> [WalletManager] {
        let cid = cardDto.cardId
        
        var walletManagers = [WalletManager]()
        
        for blockchain in blockchains {
            if let wallet = cardDto.wallets.first(where: { $0.curve == blockchain.curve }),
               let wm = try? services.walletManagerFactory.makeWalletManager(from: cid,
                                                                             walletPublicKey: wallet.publicKey,
                                                                             chainCode: wallet.chainCode,
                                                                             blockchain: blockchain) {
                walletManagers.append(wm)
            }
        }
        
        return walletManagers
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
        //TODO: Payid can work only with concrete wallet, not with the whole card
        //        if services.featuresService.isPayIdEnabled, let payIdService = PayIDService.make(from: blockchain) {
        //            vm.payIDService = payIdService
        //        }
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
    
    
    func makeAddTokensViewModel(for cardModel: CardViewModel) -> AddNewTokensViewModel {
        if let restored: AddNewTokensViewModel = get() {
            return restored
        }
        
        let vm = AddNewTokensViewModel(cardModel: cardModel)
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
                                              signer: services.signer,
                                              warningsManager: services.warningsService)
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
                               signer: services.signer,
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
    
    //    func makeTwinCardOnboardingViewModel(isFromMain: Bool) -> TwinCardOnboardingViewModel {
    //        let scanResult = services.cardsRepository.lastScanResult
    //        let twinInfo = scanResult.cardModel?.cardInfo.twinCardInfo
    //        let twinPairCid = AppTwinCardIdFormatter.format(cid: /*twinInfo?.pairCid ??*/ "", cardNumber: twinInfo?.series.pair.number ?? 1)
    //		return makeTwinCardOnboardingViewModel(state: .onboarding(withPairCid: twinPairCid, isFromMain: isFromMain))
    //	}
    //
    //    func makeTwinCardWarningViewModel(isRecreating: Bool) -> TwinCardOnboardingViewModel {
    //        makeTwinCardOnboardingViewModel(state: .warning(isRecreating: isRecreating))
    //    }
    //
    //    func makeTwinCardOnboardingViewModel(state: TwinCardOnboardingViewModel.State) -> TwinCardOnboardingViewModel {
    //        let key = String(describing: TwinCardOnboardingViewModel.self) + "_" + state.storageKey
    //        if let vm: TwinCardOnboardingViewModel = get(key: key) {
    //            vm.state = state
    //            return vm
    //        }
    //
    //        let vm = TwinCardOnboardingViewModel(state: state, imageLoader: services.imageLoaderService)
    //        initialize(vm, with: key, isResetable: false)
    //        vm.userPrefsService = services.userPrefsService
    //        return vm
    //    }
    //
    //    func makeTwinsWalletCreationViewModel(isRecreating: Bool) -> TwinsWalletCreationViewModel {
    //        if let twinInfo = services.cardsRepository.lastScanResult.cardModel!.cardInfo.twinCardInfo {
    //            services.twinsWalletCreationService.setupTwins(for: twinInfo)
    //        }
    //        if let vm: TwinsWalletCreationViewModel = get() {
    //            vm.walletCreationService = services.twinsWalletCreationService
    //            return vm
    //        }
    //
    //        let vm = TwinsWalletCreationViewModel(isRecreatingWallet: isRecreating,
    //                                              walletCreationService: services.twinsWalletCreationService,
    //                                              imageLoaderService: services.imageLoaderService)
    //        initialize(vm)
    //        return vm
    //    }
    
    func makeWalletConnectViewModel(cardModel: CardViewModel) -> WalletConnectViewModel {
        let vm = WalletConnectViewModel(cardModel: cardModel)
        initialize(vm)
        vm.walletConnectController = services.walletConnectService
        return vm
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
        //        var persistentKeys = [String]()
        //        persistentKeys.append(String(describing: type(of: MainViewModel.self)))
        //        persistentKeys.append(String(describing: type(of: ReadViewModel.self)))
        //        persistentKeys.append(String(describing: DeprecatedDisclaimerViewModel.self) + "_\(DeprecatedDisclaimerViewModel.State.accept)")
        //        persistentKeys.append(String(describing: TwinCardOnboardingViewModel.self) + "_" + TwinCardOnboardingViewModel.State.onboarding(withPairCid: "", isFromMain: false).storageKey)
        //        persistentKeys.append(String(describing: type(of: CardOnboardingViewModel.self)))
        //        persistentKeys.append(String(describing: type(of: NoteOnboardingViewModel.self)))
        
        //        let indicesToRemove = modelsStorage.keys.filter { !persistentKeys.contains($0) }
        //        indicesToRemove.forEach { modelsStorage.removeValue(forKey: $0) }
        modelsStorage.removeAll()
    }
    
    private func prepareSendViewModel(_ vm: SendViewModel) {
        initialize(vm)
        vm.ratesService = services.ratesService
        vm.featuresService = services.featuresService
        vm.emailDataCollector = SendScreenDataCollector(sendViewModel: vm)
    }
}
