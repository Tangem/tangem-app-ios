//
//  AddCustomTokenViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk
import struct TangemSdk.DerivationPath

final class AddCustomTokenViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    @Published var selectedWalletName = ""

    @Published var selectedBlockchainNetworkId: String?
    @Published var selectedBlockchainName: String = ""

    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""

    @Published var error: AlertBinder?

    @Published var addButtonDisabled = false
    @Published var isLoading = false

    @Published var contractAddressError: Error?
    @Published var decimalsError: Error?

    @Published var notificationInput: NotificationViewInput?

    var selectedBlockchainSupportsTokens: Bool {
        let blockchain = try? enteredBlockchain()
        return blockchain?.canHandleTokens ?? false
    }

    var showDerivationPaths: Bool {
        settings.hdWalletsSupported && selectedBlockchainNetworkId != nil
    }

    let canSelectWallet: Bool

    private(set) var selectedDerivationOption: AddCustomTokenDerivationOption?

    private var derivationPathByBlockchainName: [String: DerivationPath] = [:]
    private var didLogScreenAnalytics = false
    private var foundStandardToken: CoinModel?
    private var settings: ManageTokensSettings
    private var userWalletModel: UserWalletModel
    private var bag: Set<AnyCancellable> = []
    private let dataSource: ManageTokensNetworkDataSource

    private weak var coordinator: AddCustomTokenRoutable?

    init(
        userWalletModel: UserWalletModel,
        dataSource: ManageTokensDataSource,
        coordinator: AddCustomTokenRoutable
    ) {
        let networkDataSource = ManageTokensNetworkDataSource(dataSource)

        settings = Self.makeSettings(userWalletModel: userWalletModel)
        self.coordinator = coordinator
        self.dataSource = networkDataSource
        self.userWalletModel = userWalletModel
        canSelectWallet = networkDataSource.userWalletModels.count > 1
        selectedWalletName = userWalletModel.name

        bind()
    }

    func onAppear() {
        if !didLogScreenAnalytics {
            Analytics.log(.customTokenScreenOpened)
            didLogScreenAnalytics = true
        }
    }

    func createToken() {
        UIApplication.shared.endEditing()

        let tokenItem: TokenItem
        do {
            tokenItem = try enteredTokenItem()

            try checkLocalStorage()

            try userWalletModel.userTokensManager.addTokenItemPrecondition(tokenItem)
            try userWalletModel.userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
        } catch {
            self.error = error.alertBinder
            return
        }

        logSuccess(tokenItem: tokenItem)

        closeModule()
    }

    func didTapWalletSelector() {
        coordinator?.openWalletSelector(with: dataSource)
    }

    func setSelectedWallet(userWalletModel: UserWalletModel) {
        selectedWalletName = userWalletModel.name
        settings = Self.makeSettings(userWalletModel: userWalletModel)

        updateDefaultDerivationOption()
        validate()
    }

    func didTapNetworkSelector() {
        coordinator?.openNetworkSelector(
            selectedBlockchainNetworkId: selectedBlockchainNetworkId,
            blockchains: settings.supportedBlockchains
        )
    }

    func setSelectedNetwork(networkId: String) {
        guard
            let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == networkId })
        else {
            return
        }

        Analytics.log(event: .manageTokensCustomTokenNetworkSelected, params: [.blockchain: blockchain.displayName])

        selectedBlockchainNetworkId = blockchain.networkId
        selectedBlockchainName = blockchain.displayName

        updateDefaultDerivationOption()
        validate()
    }

    func didTapDerivationSelector() {
        guard
            let selectedDerivationOption,
            let selectedBlockchain = try? enteredBlockchain(),
            let derivationStyle = settings.derivationStyle,
            let defaultDerivationPath = selectedBlockchain.derivationPath(for: derivationStyle)
        else {
            return
        }

        let blockchainDerivationOptions: [AddCustomTokenDerivationOption] = settings.supportedBlockchains.compactMap {
            guard let derivationPath = $0.derivationPath(for: derivationStyle) else { return nil }
            return AddCustomTokenDerivationOption.blockchain(name: $0.displayName, derivationPath: derivationPath)
        }

        coordinator?.openDerivationSelector(
            selectedDerivationOption: selectedDerivationOption,
            defaultDerivationPath: defaultDerivationPath,
            blockchainDerivationOptions: blockchainDerivationOptions
        )
    }

    func setSelectedDerivationOption(derivationOption: AddCustomTokenDerivationOption) {
        selectedDerivationOption = derivationOption

        Analytics.log(event: .manageTokensCustomTokenNetworkSelected, params: [.derivation: derivationOption.parameterValue])

        validate()
    }

    /// This method is needed to comply with the conditions for sending events. We send an event only when the text field has lost focus
    func onChangeFocusable(field: FocusableObserveField) {
        guard foundStandardToken == nil else { return }

        switch field {
        case .name where !name.isEmpty:
            Analytics.log(.manageTokensCustomTokenName)
        case .symbol where !symbol.isEmpty:
            Analytics.log(.manageTokensCustomTokenSymbol)
        case .decimals where !decimals.isEmpty:
            Analytics.log(.manageTokensCustomTokenDecimals)
        default:
            break
        }
    }

    // MARK: - Private Implementation

    private func bind() {
        dataSource
            .selectedUserWalletModelPublisher
            .sink { [weak self] userWalletId in
                guard
                    let self,
                    let userWalletModel = dataSource.userWalletModels.first(where: { $0.userWalletId == userWalletId })
                else {
                    return
                }

                self.userWalletModel = userWalletModel
                setSelectedWallet(userWalletModel: userWalletModel)
                coordinator?.closeWalletSelector()
            }
            .store(in: &bag)

        $contractAddress
            .removeDuplicates()
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .flatMap { viewModel, contractAddress -> AnyPublisher<[CoinModel], Never> in
                let result: AnyPublisher<[CoinModel], Never>
                let contractAddressError: Error?

                do {
                    if contractAddress.isEmpty {
                        result = .just(output: [])
                        contractAddressError = nil
                    } else {
                        let enteredContractAddress = try viewModel.enteredContractAddress(
                            in: viewModel.enteredBlockchain()
                        )

                        result = viewModel.findToken(contractAddress: enteredContractAddress)
                        contractAddressError = nil

                        Analytics.log(.manageTokensCustomTokenAddress, params: [.validation: .ok])

                        viewModel.isLoading = true
                    }
                } catch {
                    Analytics.log(.manageTokensCustomTokenAddress, params: [.validation: .error])
                    result = .just(output: [])
                    contractAddressError = error
                }

                self.contractAddressError = contractAddressError
                return result
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currencyModels in
                self?.didFinishTokenSearch(currencyModels)
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            $name.removeDuplicates(),
            $symbol.removeDuplicates(),
            $decimals.removeDuplicates()
        )
        .debounce(for: 0.1, scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.validate()
        }
        .store(in: &bag)
    }

    private static func makeSettings(userWalletModel: UserWalletModel) -> ManageTokensSettings {
        let supportedBlockchains =
            Array(userWalletModel.config.supportedBlockchains)
                .filter { $0.curve.supportsDerivation && $0 != .ducatus }
                .sorted(by: \.displayName)

        return ManageTokensSettings(
            supportedBlockchains: supportedBlockchains,
            hdWalletsSupported: userWalletModel.config.hasFeature(.hdWallets),
            derivationStyle: userWalletModel.config.derivationStyle
        )
    }

    private func enteredTokenItem() throws -> TokenItem {
        let blockchain = try enteredBlockchain()
        let derivationPath = enteredDerivationPath()

        let missingTokenInformation = contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty
        if !blockchain.canHandleTokens || missingTokenInformation {
            return .blockchain(.init(blockchain, derivationPath: derivationPath))
        } else {
            let enteredContractAddress = try enteredContractAddress(in: blockchain)

            guard !name.isEmpty, !symbol.isEmpty, !decimals.isEmpty else {
                throw TokenCreationErrors.emptyFields
            }

            let maxDecimalNumber = 30
            guard
                let decimals = Int(decimals),
                0 <= decimals, decimals <= maxDecimalNumber
            else {
                throw TokenCreationErrors.invalidDecimals(precision: maxDecimalNumber)
            }

            let foundStandardTokenItem = foundStandardToken?.items.first(where: { $0.blockchain == blockchain })

            let token = Token(
                name: name,
                symbol: symbol.uppercased(),
                contractAddress: enteredContractAddress,
                decimalCount: decimals,
                id: foundStandardTokenItem?.id
            )

            return .token(token, .init(blockchain, derivationPath: derivationPath))
        }
    }

    private func validateEnteredContractAddress() throws {
        guard
            selectedBlockchainSupportsTokens,
            !contractAddress.isEmpty
        else {
            return
        }

        guard foundStandardToken != nil else {
            throw TokenSearchError.failedToFindToken
        }

        do {
            let blockchain = try enteredBlockchain()
            _ = try enteredContractAddress(in: blockchain)
        } catch {
            throw TokenSearchError.failedToFindToken
        }
    }

    private func enteredBlockchain() throws -> Blockchain {
        if let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == selectedBlockchainNetworkId }) {
            return blockchain
        } else {
            throw TokenCreationErrors.blockchainNotSelected
        }
    }

    private func enteredContractAddress(in blockchain: Blockchain) throws -> String {
        if case .binance = blockchain, !contractAddress.trimmed().isEmpty {
            return contractAddress // skip validation for binance
        }

        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        guard addressService.validate(contractAddress) else {
            throw TokenCreationErrors.invalidContractAddress
        }

        return contractAddress
    }

    private func enteredDerivationPath() -> DerivationPath? {
        if settings.hdWalletsSupported {
            return selectedDerivationOption?.derivationPath
        } else {
            return nil
        }
    }

    private func checkLocalStorage() throws {
        guard let tokenItem = try? enteredTokenItem() else { return }

        if userWalletModel.userTokensManager.contains(tokenItem) {
            throw TokenSearchError.alreadyAdded
        }
    }

    private func findToken(contractAddress: String) -> AnyPublisher<[CoinModel], Never> {
        if let currentCurrencyModel = foundStandardToken,
           let token = currentCurrencyModel.items.first?.token,
           token.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame {
            return .just(output: [currentCurrencyModel])
        }

        let requestModel = CoinsList.Request(
            supportedBlockchains: Set(settings.supportedBlockchains),
            contractAddress: contractAddress
        )

        return tangemApiService
            .loadCoins(requestModel: requestModel)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private func didFinishTokenSearch(_ currencyModels: [CoinModel]) {
        isLoading = false

        let previouslyFoundStandardToken = foundStandardToken

        let currencyModelBlockchains = currencyModels.reduce(Set<Blockchain>()) { partialResult, currencyModel in
            partialResult.union(currencyModel.items.map { $0.blockchain })
        }

        if let newBlockchain = currencyModelBlockchains.first {
            setSelectedNetwork(networkId: newBlockchain.networkId)
        }

        foundStandardToken = currencyModels.first

        if let token = foundStandardToken?.items.first?.token {
            decimals = "\(token.decimalCount)"
            symbol = token.symbol
            name = token.name
            contractAddress = token.contractAddress

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIApplication.shared.endEditing()
            }
        } else if previouslyFoundStandardToken != nil || !selectedBlockchainSupportsTokens {
            decimals = ""
            symbol = ""
            name = ""
        }

        validate()
    }

    private func validate() {
        addButtonDisabled = false
        notificationInput = nil
        decimalsError = nil

        do {
            let _ = try enteredTokenItem()
            try checkLocalStorage()
            try validateEnteredContractAddress()
        } catch {
            let dynamicValidationError = error as? DynamicValidationError
            addButtonDisabled = dynamicValidationError?.preventsFromAdding ?? false

            switch (error as? TokenCreationErrors)?.field {
            case .decimals:
                decimalsError = error
            case .none:
                break
            }

            if let notificationEventProviding = error as? NotificationEventProviding,
               let notificationEvent = notificationEventProviding.notificationEvent {
                notificationInput = NotificationViewInput(
                    style: .plain,
                    severity: .warning,
                    settings: NotificationView.Settings(
                        event: notificationEvent,
                        dismissAction: nil
                    )
                )
            }
        }
    }

    private func logSuccess(tokenItem: TokenItem) {
        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]

        if let derivationStyle = settings.derivationStyle,
           let usedDerivationPath = tokenItem.blockchainNetwork.derivationPath ?? tokenItem.blockchain.derivationPath(for: derivationStyle) {
            params[.derivation] = usedDerivationPath.rawPath
        }

        if case .token(let token, let blockchainNetwork) = tokenItem {
            params[.networkId] = blockchainNetwork.blockchain.networkId
            params[.contractAddress] = token.contractAddress
        }

        Analytics.log(event: .manageTokensCustomTokenWasAdded, params: params)
    }

    private func updateDefaultDerivationOption() {
        switch selectedDerivationOption {
        case .default, .none:
            if let blockchain = settings.supportedBlockchains.first(where: { $0.networkId == selectedBlockchainNetworkId }),
               let derivationStyle = settings.derivationStyle,
               let derivationPath = blockchain.derivationPath(for: derivationStyle) {
                selectedDerivationOption = .default(derivationPath: derivationPath)
            }
        case .custom, .blockchain:
            return
        }
    }
}

// MARK: - Navigation

extension AddCustomTokenViewModel {
    func closeModule() {
        coordinator?.dismiss()
    }
}

// MARK: - Errors

private protocol DynamicValidationError {
    var preventsFromAdding: Bool { get }
}

private protocol NotificationEventProviding {
    var notificationEvent: (any NotificationEvent)? { get }
}

extension CommonUserTokensManager.Error: DynamicValidationError {
    var preventsFromAdding: Bool {
        true
    }
}

private extension AddCustomTokenViewModel {
    enum TokenCreationErrors: DynamicValidationError, LocalizedError {
        case blockchainNotSelected
        case emptyFields
        case invalidDecimals(precision: Int)
        case invalidContractAddress

        enum Field {
            case decimals
        }

        var field: Field? {
            switch self {
            case .invalidDecimals:
                return .decimals
            case .blockchainNotSelected, .emptyFields, .invalidContractAddress:
                return nil
            }
        }

        var errorDescription: String? {
            switch self {
            case .blockchainNotSelected:
                return Localization.customTokenCreationErrorNetworkNotSelected
            case .emptyFields:
                return Localization.customTokenCreationErrorEmptyFields
            case .invalidDecimals(let precision):
                return Localization.customTokenCreationErrorWrongDecimals(precision)
            case .invalidContractAddress:
                return Localization.customTokenCreationErrorInvalidContractAddress
            }
        }

        var preventsFromAdding: Bool {
            true
        }
    }
}

private extension AddCustomTokenViewModel {
    enum TokenSearchError: DynamicValidationError, LocalizedError, NotificationEventProviding {
        case alreadyAdded
        case failedToFindToken

        var preventsFromAdding: Bool {
            false
        }

        var errorDescription: String? {
            switch self {
            case .failedToFindToken:
                return Localization.customTokenValidationErrorNotFound
            case .alreadyAdded:
                return Localization.customTokenValidationErrorAlreadyAdded
            }
        }

        var notificationEvent: (any NotificationEvent)? {
            switch self {
            case .failedToFindToken:
                return AddCustomTokenNotificationEvent.scamWarning
            case .alreadyAdded:
                return nil
            }
        }
    }
}

// MARK: - Settings

private extension AddCustomTokenViewModel {
    struct ManageTokensSettings {
        let supportedBlockchains: [Blockchain]
        let hdWalletsSupported: Bool
        let derivationStyle: DerivationStyle?
    }
}

// MARK: - Focused Observe Field

extension AddCustomTokenViewModel {
    enum FocusableObserveField {
        case name
        case symbol
        case decimals
    }
}
