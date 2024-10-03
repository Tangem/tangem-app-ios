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
import TangemStaking

protocol EmailDataCollector: LogFileProvider {}

extension EmailDataCollector {
    var fileName: String {
        LogFilesNames.infoLogs
    }

    func prepareLogFile() -> URL {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        try? logData?.write(to: url)
        return url
    }
}

private extension EmailDataCollector {
    func formatData(_ collectedInfo: [EmailCollectedData], appendDeviceInfo: Bool = true) -> Data? {
        let sessionPrefix = "Session ID: \(AppConstants.sessionId)\n"
        let collectedString = collectedInfo.reduce("") { $0 + $1.type.title + $1.data + "\n" } + (appendDeviceInfo ? DeviceInfoProvider.info() : "")
        let messageToConvert = "\(sessionPrefix)\n\(collectedString)"
        return messageToConvert.data(using: .utf8)
    }
}

// MARK: - NegativeFeedbackDataCollector

struct NegativeFeedbackDataCollector: EmailDataCollector {
    var logData: Data? {
        formatData(userWalletEmailData)
    }

    private let userWalletEmailData: [EmailCollectedData]

    init(userWalletEmailData: [EmailCollectedData]) {
        self.userWalletEmailData = userWalletEmailData
    }
}

// MARK: - SendScreenDataCollector

struct SendScreenDataCollector: EmailDataCollector {
    var logData: Data? {
        var data = userWalletEmailData
        data.append(.separator(.dashes))

        data.append(EmailCollectedData(
            type: .card(.blockchain),
            data: walletModel.blockchainNetwork.blockchain.displayName
        ))

        switch amount.type {
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
            data.append(EmailCollectedData(type: .token(.decimals), data: "\(token.decimalCount)"))
            data.append(EmailCollectedData(type: .token(.contractAddress), data: token.contractAddress))
        case .coin, .reserve, .feeResource:
            break
        }

        // Did display current wallet manager curreny host by provider
        data.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.blockchainDataProvider.currentHost))

        if let outputsDescription = walletModel.blockchainDataProvider.outputsCount?.description {
            data.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
        }

        if let errorDescription = lastError?.localizedDescription {
            data.append(EmailCollectedData(type: .error, data: errorDescription))
        }

        let derivationPath = walletModel.wallet.publicKey.derivationPath
        data.append(EmailCollectedData(type: .wallet(.derivationPath), data: derivationPath?.rawPath ?? "[default]"))

        data.append(.separator(.dashes))

        data.append(contentsOf: [
            EmailCollectedData(type: .send(.sourceAddress), data: walletModel.wallet.address),
            EmailCollectedData(type: .send(.destinationAddress), data: destination),
            EmailCollectedData(type: .send(.amount), data: amount.description),
            EmailCollectedData(type: .send(.fee), data: fee.description),
            EmailCollectedData(type: .send(.isFeeIncluded), data: "\(isFeeIncluded)"),
        ])

        if let stakingAction {
            data.append(EmailCollectedData(type: .staking(.stakingAction), data: stakingAction.title))
        }

        if let validator {
            data.append(contentsOf: [
                EmailCollectedData(type: .staking(.validatorName), data: validator.name),
                EmailCollectedData(type: .staking(.validatorAddress), data: validator.address),
            ])
        }

        // The last retry attempt by the host caused an error with txHex string
        if let exceptionHost = lastError?.lastRetryHost, let txHex = lastError?.tx {
            data.append(EmailCollectedData(type: .wallet(.exceptionWalletManagerHost), data: exceptionHost))
            data.append(EmailCollectedData(type: .send(.transactionHex), data: txHex))
        }

        return formatData(data)
    }

    private let userWalletEmailData: [EmailCollectedData]
    private let walletModel: WalletModel
    private let fee: Amount
    private let destination: String
    private let amount: Amount
    private let isFeeIncluded: Bool
    private let lastError: SendTxError?
    private let stakingAction: StakingAction.ActionType?
    private let validator: ValidatorInfo?

    init(
        userWalletEmailData: [EmailCollectedData],
        walletModel: WalletModel,
        fee: Amount,
        destination: String,
        amount: Amount,
        isFeeIncluded: Bool,
        lastError: SendTxError?,
        stakingAction: StakingAction.ActionType?,
        validator: ValidatorInfo?
    ) {
        self.userWalletEmailData = userWalletEmailData
        self.walletModel = walletModel
        self.fee = fee
        self.destination = destination
        self.amount = amount
        self.isFeeIncluded = isFeeIncluded
        self.lastError = lastError
        self.stakingAction = stakingAction
        self.validator = validator
    }
}

// MARK: - PushScreenDataCollector

struct PushScreenDataCollector: EmailDataCollector {
    var logData: Data? {
        var data = userWalletEmailData
        data.append(.separator(.dashes))
        switch amount.type {
        case .coin:
            data.append(EmailCollectedData(type: .card(.blockchain), data: amount.currencySymbol))
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        default:
            break
        }

        data.append(contentsOf: [
            EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.blockchainDataProvider.currentHost),
            EmailCollectedData(type: .error, data: lastError?.localizedDescription ?? "Unknown error"),
            .separator(.dashes),
            EmailCollectedData(type: .send(.pushingTxHash), data: pushingTxHash),
            EmailCollectedData(type: .send(.pushingFee), data: pushingFee?.description ?? "[unknown]"),
            EmailCollectedData(type: .send(.sourceAddress), data: source),
            EmailCollectedData(type: .send(.destinationAddress), data: destination),
            EmailCollectedData(type: .send(.amount), data: amount.description),
            EmailCollectedData(type: .send(.fee), data: fee?.description ?? "[unknown]"),
        ])

        return formatData(data)
    }

    private let userWalletEmailData: [EmailCollectedData]
    private let walletModel: WalletModel
    private let fee: Amount?
    private let pushingFee: Amount?
    private let destination: String
    private let source: String
    private let amount: Amount
    private let pushingTxHash: String
    private let lastError: Error?

    init(userWalletEmailData: [EmailCollectedData], walletModel: WalletModel, fee: Amount?, pushingFee: Amount?, destination: String, source: String, amount: Amount, pushingTxHash: String, lastError: Error?) {
        self.userWalletEmailData = userWalletEmailData
        self.walletModel = walletModel
        self.fee = fee
        self.pushingFee = pushingFee
        self.destination = destination
        self.source = source
        self.amount = amount
        self.pushingTxHash = pushingTxHash
        self.lastError = lastError
    }
}

// MARK: - DetailsFeedbackDataCollector

struct DetailsFeedbackDataCollector: EmailDataCollector {
    var logData: Data? {
        var dataToFormat: [EmailCollectedData] = []

        for dataItem in data {
            dataToFormat.append(contentsOf: dataItem.userWalletEmailData)

            for walletModel in dataItem.walletModels {
                dataToFormat.append(.separator(.dashes))
                dataToFormat.append(EmailCollectedData(type: .card(.blockchain), data: walletModel.wallet.blockchain.displayName))

                let derivationPath = walletModel.wallet.publicKey.derivationPath
                dataToFormat.append(EmailCollectedData(type: .wallet(.derivationPath), data: derivationPath?.rawPath ?? "[default]"))

                if let outputsDescription = walletModel.blockchainDataProvider.outputsCount?.description {
                    dataToFormat.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
                }

                if let token = walletModel.amountType.token {
                    dataToFormat.append(EmailCollectedData(type: .token(.id), data: token.id ?? "[custom token]"))
                    dataToFormat.append(EmailCollectedData(type: .token(.decimals), data: "\(token.decimalCount)"))
                    dataToFormat.append(EmailCollectedData(type: .token(.name), data: token.name))
                    dataToFormat.append(EmailCollectedData(type: .token(.contractAddress), data: token.contractAddress))
                }

                dataToFormat.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: walletModel.blockchainDataProvider.currentHost))
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

            dataToFormat.append(.separator(.dashes))
            dataToFormat.append(.separator(.dashes))
        }

        return formatData(dataToFormat)
    }

    private let data: [DetailsFeedbackData]

    init(data: [DetailsFeedbackData]) {
        self.data = data
    }
}

// MARK: - DetailsFeedbackData

struct DetailsFeedbackData {
    let userWalletEmailData: [EmailCollectedData]
    let walletModels: [WalletModel]
}

// MARK: - TokenErrorDescriptionDataCollector

struct TokenErrorDescriptionDataCollector: EmailDataCollector {
    var logData: Data? {
        var dataToFormat: [EmailCollectedData] = []
        dataToFormat.append(.separator(.dashes))

        dataToFormat.append(EmailCollectedData(type: .token(.id), data: tokenId))
        dataToFormat.append(EmailCollectedData(type: .token(.name), data: tokenName))

        dataToFormat.append(.separator(.dashes))
        return formatData(dataToFormat)
    }

    private let tokenId: String
    private let tokenName: String

    init(tokenId: String, tokenName: String) {
        self.tokenId = tokenId
        self.tokenName = tokenName
    }
}
