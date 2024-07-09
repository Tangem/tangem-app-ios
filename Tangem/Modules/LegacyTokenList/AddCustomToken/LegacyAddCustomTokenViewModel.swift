//
//  LegacyAddCustomTokenViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 11/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import struct TangemSdk.DerivationPath
import enum TangemSdk.TangemSdkError

class LegacyAddCustomTokenViewModel: ObservableObject {
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    @Published var customDerivationPath = ""

    @Published var blockchainsPicker: LegacyPickerModel = .empty
    @Published var derivationsPicker: LegacyPickerModel = .empty

    @Published var error: AlertBinder?

    @Published var warningContainer = WarningsContainer()
    @Published var addButtonDisabled = false
    @Published var isLoading = false

    var canEnterTokenDetails: Bool {
        selectedBlockchainSupportsTokens
    }

    var showDerivationPaths: Bool {
        cardHasDifferentDerivationPaths
    }

    var showCustomDerivationPath: Bool {
        derivationsPicker.selection == customDerivationItemID
    }

    @Published private var cardHasDifferentDerivationPaths: Bool = true

    private var selectedBlockchainSupportsTokens: Bool {
        let blockchain = try? enteredBlockchain()
        return blockchain?.canHandleCustomTokens ?? false
    }

    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    private var derivationPathByBlockchainName: [String: DerivationPath] = [:]
    private var foundStandardToken: CoinModel?
    private unowned let coordinator: LegacyAddCustomTokenRoutable
    private let userTokensManager: UserTokensManager

    private let defaultDerivationItemID = "default-derivation"
    private let customDerivationItemID = "custom-derivation"
    private let settings: LegacyManageTokensSettings

    private var supportedBlockchains: Set<Blockchain> {
        settings.supportedBlockchains
            .filter {
                $0.curve.supportsDerivation
            }
    }

    init(
        settings: LegacyManageTokensSettings,
        userTokensManager: UserTokensManager,
        coordinator: LegacyAddCustomTokenRoutable
    ) {
        self.settings = settings
        self.userTokensManager = userTokensManager
        self.coordinator = coordinator

        $contractAddress.removeDuplicates()
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .flatMap { [unowned self] contractAddress -> AnyPublisher<[CoinModel], Never> in
                isLoading = true

                guard !contractAddress.isEmpty else {
                    return .just(output: [])
                }

                return findToken(contractAddress: contractAddress)
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] currencyModels in
                didFinishTokenSearch(currencyModels)
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            $blockchainsPicker.map { $0.selection }.removeDuplicates(),
            $derivationsPicker.map { $0.selection }.removeDuplicates(),
            $customDerivationPath.removeDuplicates()
        )
        .debounce(for: 0.1, scheduler: DispatchQueue.main)
        .sink { [unowned self] _ in
            didChangeBlockchain()
        }
        .store(in: &bag)

        // It is necessary to ensure that the steps of validating the existence of a token are not lost, since the validation includes a check for these fields (Line - 243)
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

    func createToken() {
        UIApplication.shared.endEditing()

        let tokenItem: TokenItem
        do {
            tokenItem = try enteredTokenItem()

            try validateExistingCurves(for: tokenItem)

            if case .token(_, let blockchainNetwork) = tokenItem,
               case .solana = blockchainNetwork.blockchain,
               !settings.longHashesSupported {
                throw TokenCreationErrors.tokensNotSupported(blockchainDisplayName: blockchainNetwork.blockchain.displayName)
            }
        } catch {
            self.error = error.alertBinder
            return
        }

        userTokensManager.add(tokenItem) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                closeModule()

                logSuccess(tokenItem: tokenItem)
            case .failure(let error):
                if case TangemSdkError.userCancelled = error {
                    return
                }

                self.error = error.alertBinder
            }
        }
    }

    func onAppear() {
        Analytics.log(.customTokenScreenOpened)
        updateBlockchains(supportedBlockchains)
        updateDerivationPaths()
    }

    func onDisappear() {
        blockchainsPicker = .empty
        derivationsPicker = .empty
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
    }

    private func updateBlockchains(_ blockchains: Set<Blockchain>, newSelectedBlockchain: Blockchain? = nil) {
        let defaultItem = (Localization.customTokenNetworkInputNotSelected, "")

        let newBlockchains = [defaultItem] + blockchains.sorted {
            $0.displayName < $1.displayName
        }.map {
            ($0.displayName, $0.codingKey)
        }
        blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })
        derivationPathByBlockchainName = Dictionary(uniqueKeysWithValues: blockchains.compactMap {
            guard let derivationStyle = settings.derivationStyle,
                  let derivationPath = $0.derivationPath(for: derivationStyle) else { return nil }
            return ($0.codingKey, derivationPath)
        })

        var newBlockchainName = blockchainsPicker.selection
        if let newSelectedBlockchain = newSelectedBlockchain {
            newBlockchainName = newSelectedBlockchain.codingKey
        } else if blockchains.count == 1, let firstBlockchain = blockchains.first {
            newBlockchainName = firstBlockchain.codingKey
        } else if blockchainByName[blockchainsPicker.selection] == nil {
            newBlockchainName = ""
        }

        blockchainsPicker = .init(items: newBlockchains, selection: newBlockchainName, isEnabled: blockchains.count > 1)
    }

    private func updateDerivationPaths() {
        let defaultItem = (Localization.customTokenDerivationPathDefault, defaultDerivationItemID)

        let customItem = (Localization.customTokenCustomDerivation, customDerivationItemID)

        let derivations: [(String, String)]
        if !settings.hdWalletsSupported {
            derivations = []
        } else {
            derivations = supportedBlockchains
                .compactMap {
                    guard let derivationStyle = settings.derivationStyle,
                          let derivationPath = $0.derivationPath(for: derivationStyle) else { return nil }

                    let derivationPathFormatted = derivationPath.rawPath
                    let blockchainName = $0.codingKey
                    let description = "\($0.displayName) (\(derivationPathFormatted))"
                    return (description, blockchainName)
                }
                .sorted {
                    $0.0 < $1.0
                }
        }

        let uniqueDerivations = Set(derivations.map(\.1))
        cardHasDifferentDerivationPaths = uniqueDerivations.count > 1
        let newDerivationSelection = derivationsPicker.selection
        derivationsPicker = .init(items: [defaultItem, customItem] + derivations, selection: newDerivationSelection)
    }

    private func enteredTokenItem() throws -> TokenItem {
        let blockchain = try enteredBlockchain()
        let derivationPath = enteredDerivationPath()

        let missingTokenInformation = contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty
        if !blockchain.canHandleCustomTokens || missingTokenInformation {
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
        guard !contractAddress.isEmpty else {
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

    private func validateDerivationPath() throws {
        guard customDerivationItemID == derivationsPicker.selection else {
            return
        }

        let derivationPath = try? DerivationPath(rawPath: customDerivationPath)
        if derivationPath == nil {
            throw DerivationPathError.invalidDerivationPath
        }
    }

    private func validateExistingCurves(for tokenItem: TokenItem) throws {
        guard settings.existingCurves.contains(tokenItem.blockchain.curve) else {
            throw TokenCreationErrors.unsupportedCurve(tokenItem.blockchain)
        }

        return
    }

    private func enteredBlockchain() throws -> Blockchain {
        guard let blockchain = blockchainByName[blockchainsPicker.selection] else {
            throw TokenCreationErrors.blockchainNotSelected
        }

        return blockchain
    }

    private func enteredDerivationPath() -> DerivationPath? {
        let derivationItemID = derivationsPicker.selection

        switch derivationItemID {
        case defaultDerivationItemID:
            return nil
        case customDerivationItemID:
            return try? DerivationPath(rawPath: customDerivationPath)
        default:
            // ID is a blockchain name
            return derivationPathByBlockchainName[derivationItemID]
        }
    }

    private func enteredContractAddress(in blockchain: Blockchain) throws -> String {
        let contractAddress = convertContractAddressIfPossible(contractAddress, in: blockchain)
        let validator = ContractAddressValidatorFactory(blockchain: blockchain).makeValidator()

        guard validator.validate(contractAddress) else {
            throw TokenCreationErrors.invalidContractAddress
        }

        return contractAddress
    }

    private func convertContractAddressIfPossible(_ contractAddress: String, in blockchain: Blockchain?) -> String {
        guard let blockchain else {
            return contractAddress
        }

        let converter = CustomTokenContractAddressConverter(blockchain: blockchain)
        let enteredSymbol = symbol.isEmpty ? nil : symbol
        return converter.convert(contractAddress, symbol: enteredSymbol)
    }

    private func checkLocalStorage() throws {
        guard let tokenItem = try? enteredTokenItem() else {
            return
        }

        if userTokensManager.contains(tokenItem) {
            throw TokenSearchError.alreadyAdded
        }
    }

    private func findToken(contractAddress: String) -> AnyPublisher<[CoinModel], Never> {
        let blockchain = try? enteredBlockchain()
        let contractAddress = convertContractAddressIfPossible(contractAddress, in: blockchain)

        if let currentCurrencyModel = foundStandardToken,
           let token = currentCurrencyModel.items.first?.token,
           token.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame {
            return .just(output: [currentCurrencyModel])
        }

        let requestModel = CoinsList.Request(
            supportedBlockchains: supportedBlockchains,
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

        let blockchains = supportedBlockchains
        updateBlockchains(blockchains, newSelectedBlockchain: currencyModelBlockchains.first)

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

    private func didChangeBlockchain() {
        validate()
    }

    private func validate() {
        addButtonDisabled = false
        warningContainer.removeAll()

        do {
            try validateDerivationPath()
            try checkLocalStorage()
            try validateEnteredContractAddress()
        } catch {
            let dynamicValidationError = error as? DynamicValidationError
            addButtonDisabled = dynamicValidationError?.preventsFromAdding ?? false

            if let localizedError = error as? LocalizedError {
                let warning = AppWarning(title: Localization.commonWarning, message: localizedError.localizedDescription, priority: .warning)
                warningContainer.add(warning)
            }
        }
    }

    private func logSuccess(tokenItem: TokenItem) {
        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]

        if let derivationStyle = settings.derivationStyle,
           let usedDerivationPath = tokenItem.blockchainNetwork.derivationPath ?? tokenItem.blockchain.derivationPath(for: derivationStyle) {
            params[.derivationPath] = usedDerivationPath.rawPath
        }

        if case .token(let token, let blockchainNetwork) = tokenItem {
            params[.networkId] = blockchainNetwork.blockchain.networkId
            params[.contractAddress] = token.contractAddress
        }

        Analytics.log(event: .manageTokensCustomTokenWasAdded, params: params)
    }
}

// MARK: - Navigation

extension LegacyAddCustomTokenViewModel {
    func closeModule() {
        coordinator.closeModule()
    }
}

private protocol DynamicValidationError {
    var preventsFromAdding: Bool { get }
}

private extension LegacyAddCustomTokenViewModel {
    enum TokenCreationErrors: LocalizedError {
        case blockchainNotSelected
        case unsupportedCurve(Blockchain)
        case emptyFields
        case tokensNotSupported(blockchainDisplayName: String)
        case invalidDecimals(precision: Int)
        case invalidContractAddress
        case invalidDerivationPath

        var errorDescription: String? {
            switch self {
            case .blockchainNotSelected:
                return Localization.customTokenCreationErrorNetworkNotSelected
            case .unsupportedCurve(let blockchain):
                return Localization.alertManageTokensUnsupportedCurveMessage(blockchain.displayName)
            case .emptyFields:
                return Localization.customTokenCreationErrorEmptyFields
            case .tokensNotSupported(let blockchainDisplayName):
                return Localization.alertManageTokensUnsupportedMessage(blockchainDisplayName)
            case .invalidDecimals(let precision):
                return Localization.customTokenCreationErrorWrongDecimals(precision)
            case .invalidContractAddress:
                return Localization.customTokenCreationErrorInvalidContractAddress
            case .invalidDerivationPath:
                return Localization.customTokenCreationErrorInvalidDerivationPath
            }
        }
    }

    enum TokenSearchError: DynamicValidationError, LocalizedError {
        case alreadyAdded
        case failedToFindToken

        var preventsFromAdding: Bool {
            switch self {
            case .alreadyAdded:
                return true
            case .failedToFindToken:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .failedToFindToken:
                return Localization.customTokenValidationErrorNotFound
            case .alreadyAdded:
                return Localization.customTokenValidationErrorAlreadyAdded
            }
        }
    }

    enum DerivationPathError: DynamicValidationError, LocalizedError {
        case invalidDerivationPath

        var preventsFromAdding: Bool {
            switch self {
            case .invalidDerivationPath:
                return true
            }
        }

        var errorDescription: String? {
            switch self {
            case .invalidDerivationPath:
                return Localization.customTokenInvalidDerivationPath
            }
        }
    }
}

struct LegacyPickerModel: Identifiable {
    let id = UUID()
    let items: [(String, String)]
    var selection: String
    var isEnabled: Bool = true

    static var empty: LegacyPickerModel {
        .init(items: [], selection: "")
    }
}
