//
//  AppScanTask.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemVisa

enum DefaultWalletData: Codable {
    case file(WalletData)
    case legacy(WalletData)
    case twin(WalletData, TwinData)
    case visa(activationInput: VisaCardActivationInput, tokens: VisaAuthorizationTokens?)
    case none

    var twinData: TwinData? {
        if case .twin(_, let data) = self {
            return data
        }

        return nil
    }
}

struct AppScanTaskResponse {
    let card: Card
    let walletData: DefaultWalletData
    let primaryCard: PrimaryCard?

    func getCardInfo() -> CardInfo {
        var cardInfo = CardInfo(
            card: CardDTO(card: card),
            walletData: walletData,
            name: "",
            primaryCard: primaryCard
        )

        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        cardInfo.name = config.cardName
        return cardInfo
    }
}

final class AppScanTask: CardSessionRunnable {
    let shouldAskForAccessCode: Bool

    private let performDerivations: Bool
    private var walletData: DefaultWalletData = .none
    private var primaryCard: PrimaryCard?
    private var linkingCommand: StartPrimaryCardLinkingCommand?

    init(
        shouldAskForAccessCode: Bool = false,
        performDerivations: Bool = true
    ) {
        self.shouldAskForAccessCode = shouldAskForAccessCode
        self.performDerivations = performDerivations
    }

    deinit {
        AppLog.shared.debug("AppScanTask deinit")
    }

    /// read ->  readTwinData or note Data or derive wallet's keys -> appendWallets(createwallets+ scan)  -> attestation
    public func run(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let visaUtils = VisaUtilities(isTestnet: false)
        if FirmwareVersion.visaRange.contains(card.firmwareVersion.doubleValue) && visaUtils.batchId.contains(card.batchId) {
            readVisaCard(session, completion)
            return
        }

        // tmp disable reading cards with imported wallets
        if card.firmwareVersion < .ed25519Slip0010Available,
           card.wallets.contains(where: { $0.isImported == true }) {
            completion(.failure(.wrongCardType(nil)))
            return
        }

        if let legacyWalletData = session.environment.walletData,
           legacyWalletData.blockchain != "ANY" {
            walletData = .legacy(legacyWalletData)
        }

        readExtra(session: session, completion: completion)
    }

    private func readExtra(session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if TwinCardSeries.series(for: card.cardId) != nil {
            readTwin(card, session: session, completion: completion)
            return
        }

        if card.firmwareVersion.doubleValue >= 4.39 {
            if card.settings.maxWalletsCount == 1 {
                readFile(card, session: session, completion: completion)
            } else {
                readPrimaryIfNeeded(card, session, completion)
            }

            return
        }

        runScanTask(session, completion)
    }

    private func readPrimaryIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let isWalletInOnboarding = AppSettings.shared.cardsStartedActivation.contains(card.cardId)

        if isWalletInOnboarding,
           card.settings.isBackupAllowed, card.backupStatus == .noBackup {
            readPrimaryCard(session, completion)
            return
        } else {
            deriveKeysIfNeeded(session, completion)
            return
        }
    }

    private func readFile(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        func exit() {
            readPrimaryIfNeeded(card, session, completion)
        }

        let readFileCommand = ReadFilesTask(fileName: "blockchainInfo", walletPublicKey: nil)
        readFileCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let file = response.first,
                      let tlv = Tlv.deserialize(file.data),
                      let fileSignature = file.signature,
                      let fileCounter = file.counter,
                      let walletData = try? WalletDataDeserializer().deserialize(decoder: TlvDecoder(tlv: tlv)) else {
                    exit()
                    return
                }

                let dataToVerify = Data(hexString: card.cardId) + file.data + fileCounter.bytes4
                let isVerified: Bool = (try? CryptoUtils.verify(
                    curve: .secp256k1,
                    publicKey: card.issuer.publicKey,
                    message: dataToVerify,
                    signature: fileSignature
                )) ?? false

                guard isVerified else {
                    exit()
                    return
                }

                if walletData.blockchain != "ANY" {
                    self.walletData = .file(walletData)
                }

                exit()
            case .failure(let error):
                switch error {
                case .fileNotFound, .insNotSupported:
                    exit()
                default:
                    completion(.failure(error))
                }
            }
        }
    }

    private func readTwin(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let readIssuerDataCommand = ReadIssuerDataCommand()
        readIssuerDataCommand.run(in: session) { result in
            switch result {
            case .success(let response):

                if let walletData = session.environment.walletData {
                    let twinData = self.decodeTwinFile(from: card, twinIssuerData: response.issuerData)
                    self.walletData = .twin(walletData, twinData)
                }

                self.runScanTask(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func decodeTwinFile(from card: Card, twinIssuerData: Data) -> TwinData {
        var pairPublicKey: Data?

        if let walletPubKey = card.wallets.first?.publicKey, twinIssuerData.count == 129 {
            let pairPubKey = twinIssuerData[0 ..< 65]
            let signature = twinIssuerData[65 ..< twinIssuerData.count]
            if (try? Secp256k1Signature(with: signature).verify(with: walletPubKey, message: pairPubKey)) ?? false {
                pairPublicKey = pairPubKey
            }
        }

        return TwinData(
            series: TwinCardSeries.series(for: card.cardId)!,
            pairPublicKey: pairPublicKey
        )
    }

    private func readPrimaryCard(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        linkingCommand = StartPrimaryCardLinkingCommand()
        linkingCommand!.run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                self.primaryCard = primaryCard
                self.deriveKeysIfNeeded(session, completion)
            case .failure: // ignore any error
                self.deriveKeysIfNeeded(session, completion)
            }
        }
    }

    private func readVisaCard(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let handler = VisaCardScanHandler()
        handler.handleVisaCardScan(session: session) { result in
            switch result {
            case .success(let success):
                self.walletData = success
                self.readExtra(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(handler) {}
        }
    }

    private func deriveKeysIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let plainCard = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard performDerivations,
              !plainCard.wallets.isEmpty,
              plainCard.settings.isHDWalletAllowed else {
            runScanTask(session, completion)
            return
        }

        let card = CardDTO(card: plainCard)
        let config = config(for: card)
        var derivations: [EllipticCurve: [DerivationPath]] = [:]

        if let seed = config.userWalletIdSeed {
            let tokenItemsRepository = CommonTokenItemsRepository(key: UserWalletId(with: seed).stringValue)

            // Force add blockchains for demo cards
            if let persistentBlockchains = config.persistentBlockchains {
                let converter = StorageEntryConverter()
                tokenItemsRepository.append(converter.convertToStoredUserTokens(persistentBlockchains))
            }

            let savedItems = tokenItemsRepository.getList().entries

            savedItems.forEach { item in
                if let wallet = card.wallets.first(where: { $0.curve == item.blockchainNetwork.blockchain.curve }) {
                    derivations[wallet.curve, default: []].append(contentsOf: item.blockchainNetwork.derivationPaths())
                }
            }
        }

        if derivations.isEmpty {
            runScanTask(session, completion)
            return
        }

        var sdkConfig = session.environment.config
        sdkConfig.defaultDerivationPaths = derivations
        session.updateConfig(with: sdkConfig)
        runScanTask(session, completion)
    }

    private func runScanTask(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let scanTask = ScanTask()
        scanTask.run(in: session) { result in
            switch result {
            case .success:
                self.complete(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        completion(.success(AppScanTaskResponse(
            card: card,
            walletData: walletData,
            primaryCard: primaryCard
        )))
    }

    private func config(for card: CardDTO) -> UserWalletConfig {
        let cardInfo = CardInfo(card: card, walletData: walletData, name: "")
        return UserWalletConfigFactory(cardInfo).makeConfig()
    }
}
