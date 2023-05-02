//
//  DataCollectors.swift
//  Tangem
//
//  Created by Andrew Son on 18/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol EmailDataCollector: LogFileProvider {}

extension EmailDataCollector {
    var fileName: String {
        "infoLogs.txt"
    }

    func prepareLogFile() -> URL {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        try? logData?.write(to: url)
        return url
    }
}

fileprivate extension EmailDataCollector {
    func formatData(_ collectedInfo: [EmailCollectedData], appendDeviceInfo: Bool = true) -> Data? {
        let collectedString = collectedInfo.reduce("") { $0 + $1.type.title + $1.data + "\n" } + (appendDeviceInfo ? DeviceInfoProvider.info() : "")
        return collectedString.data(using: .utf8)
    }
}

struct NegativeFeedbackDataCollector: EmailDataCollector {
    var logData: Data? {
        formatData(userWalletEmailData)
    }

    private let userWalletEmailData: [EmailCollectedData]

    init(userWalletEmailData: [EmailCollectedData]) {
        self.userWalletEmailData = userWalletEmailData
    }
}

struct SendScreenDataCollector: EmailDataCollector {
    var logData: Data? {
        var data = userWalletEmailData
        data.append(.separator(.dashes))

        data.append(EmailCollectedData(
            type: .card(.blockchain),
            data: walletModel.blockchainNetwork.blockchain.displayName
        ))

        switch amountToSend.type {
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        case .coin, .reserve:
            break
        }

        data.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.walletManager.currentHost))

        if let outputsDescription = walletModel.walletManager.outputsCount?.description {
            data.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
        }

        if let errorDescription = lastError?.localizedDescription {
            data.append(EmailCollectedData(type: .error, data: errorDescription))
        }

        let derivationPath = walletModel.walletManager.wallet.publicKey.derivationPath
        data.append(EmailCollectedData(type: .wallet(.derivationPath), data: derivationPath?.rawPath ?? "[default]"))

        data.append(.separator(.dashes))

        data.append(contentsOf: [
            EmailCollectedData(type: .send(.sourceAddress), data: walletModel.wallet.address),
            EmailCollectedData(type: .send(.destinationAddress), data: destination),
            EmailCollectedData(type: .send(.amount), data: amountText),
            EmailCollectedData(type: .send(.fee), data: feeText),
        ])

        if let txHex = txHex {
            data.append(EmailCollectedData(type: .send(.transactionHex), data: txHex))
        }

        return formatData(data)
    }

    private var txHex: String? {
        if let sendError = lastError as? SendTxError {
            return sendError.tx
        }

        return nil
    }

    private let userWalletEmailData: [EmailCollectedData]
    private let walletModel: WalletModel
    private let amountToSend: Amount
    private let feeText: String
    private let destination: String
    private let amountText: String
    private let lastError: Error?

    init(userWalletEmailData: [EmailCollectedData], walletModel: WalletModel, amountToSend: Amount, feeText: String, destination: String, amountText: String, lastError: Error?) {
        self.userWalletEmailData = userWalletEmailData
        self.walletModel = walletModel
        self.amountToSend = amountToSend
        self.feeText = feeText
        self.destination = destination
        self.amountText = amountText
        self.lastError = lastError
    }
}

struct PushScreenDataCollector: EmailDataCollector {
    var logData: Data? {
        var data = userWalletEmailData
        data.append(.separator(.dashes))
        switch amountToSend.type {
        case .coin:
            data.append(EmailCollectedData(type: .card(.blockchain), data: amountToSend.currencySymbol))
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        default:
            break
        }

        data.append(contentsOf: [
            EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.walletManager.currentHost),
            EmailCollectedData(type: .error, data: lastError?.localizedDescription ?? "Unknown error"),
            .separator(.dashes),
            EmailCollectedData(type: .send(.pushingTxHash), data: pushingTxHash),
            EmailCollectedData(type: .send(.pushingFee), data: pushingFeeText),
            EmailCollectedData(type: .send(.sourceAddress), data: source),
            EmailCollectedData(type: .send(.destinationAddress), data: destination),
            EmailCollectedData(type: .send(.amount), data: amountText),
            EmailCollectedData(type: .send(.fee), data: feeText),
        ])

        return formatData(data)
    }

    private let userWalletEmailData: [EmailCollectedData]
    private let walletModel: WalletModel
    private let amountToSend: Amount
    private let feeText: String
    private let pushingFeeText: String
    private let destination: String
    private let source: String
    private let amountText: String
    private let pushingTxHash: String
    private let lastError: Error?

    init(userWalletEmailData: [EmailCollectedData], walletModel: WalletModel, amountToSend: Amount, feeText: String, pushingFeeText: String, destination: String, source: String, amountText: String, pushingTxHash: String, lastError: Error?) {
        self.userWalletEmailData = userWalletEmailData
        self.walletModel = walletModel
        self.amountToSend = amountToSend
        self.feeText = feeText
        self.pushingFeeText = pushingFeeText
        self.destination = destination
        self.source = source
        self.amountText = amountText
        self.pushingTxHash = pushingTxHash
        self.lastError = lastError
    }
}

struct DetailsFeedbackDataCollector: EmailDataCollector {
    var logData: Data? {
        var dataToFormat = userWalletEmailData

        for walletModel in cardModel.walletModels {
            dataToFormat.append(.separator(.dashes))
            dataToFormat.append(EmailCollectedData(type: .card(.blockchain), data: walletModel.wallet.blockchain.displayName))

            let derivationPath = walletModel.wallet.publicKey.derivationPath
            dataToFormat.append(EmailCollectedData(type: .wallet(.derivationPath), data: derivationPath?.rawPath ?? "[default]"))

            if let xpubKey = walletModel.wallet.xpubKey {
                dataToFormat.append(EmailCollectedData(type: .wallet(.xpub), data: xpubKey))
            }

            if let outputsDescription = walletModel.walletManager.outputsCount?.description {
                dataToFormat.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
            }

            let tokens = walletModel.allTokenItemViewModels().compactMap { $0.amountType.token }

            if !tokens.isEmpty {
                dataToFormat.append(EmailCollectedData(type: .token(.tokens), data: ""))
            }

            for token in tokens {
                dataToFormat.append(EmailCollectedData(type: .token(.id), data: token.id ?? "[custom token]"))
                dataToFormat.append(EmailCollectedData(type: .token(.name), data: token.name))
                dataToFormat.append(EmailCollectedData(type: .token(.contractAddress), data: token.contractAddress))
            }

            dataToFormat.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.walletManager.currentHost))
            if walletModel.addressNames.count > 1 {
                var explorerLinks = "Multiple explorers links: "
                var addresses = "Multiple addresses: "
                let suffix = " ; \n"
                walletModel.addressNames.enumerated().forEach {
                    let namePrefix = $0.element + " - "
                    addresses += namePrefix + walletModel.displayAddress(for: $0.offset) + suffix
                    explorerLinks += namePrefix + (walletModel.exploreURL(for: $0.offset)?.absoluteString ?? "") + suffix
                }
                explorerLinks.removeLast(suffix.count)
                addresses.removeLast(suffix.count)

                dataToFormat.append(EmailCollectedData(type: .wallet(.walletAddress), data: addresses))
                dataToFormat.append(EmailCollectedData(type: .wallet(.explorerLink), data: explorerLinks))
            } else if walletModel.addressNames.count == 1 {
                dataToFormat.append(EmailCollectedData(type: .wallet(.walletAddress), data: walletModel.displayAddress(for: 0)))
                dataToFormat.append(EmailCollectedData(type: .wallet(.explorerLink), data: walletModel.exploreURL(for: 0)?.absoluteString ?? ""))
            }
        }

        return formatData(dataToFormat)
    }

    private let cardModel: CardViewModel
    private let userWalletEmailData: [EmailCollectedData]

    init(cardModel: CardViewModel, userWalletEmailData: [EmailCollectedData]) {
        self.cardModel = cardModel
        self.userWalletEmailData = userWalletEmailData
    }
}
