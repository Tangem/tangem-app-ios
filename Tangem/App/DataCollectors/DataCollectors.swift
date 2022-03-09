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

protocol EmailDataCollector {
    var dataForEmail: String { get }
    var attachment: Data? { get }
}

extension EmailDataCollector {
    var attachment: Data? { nil }
    
    fileprivate func collectData(from cardInfo: CardInfo) -> [EmailCollectedData] {
        var data = [
            EmailCollectedData(type: .card(.cardId), data: cardInfo.card.cardId),
            EmailCollectedData(type: .card(.firmwareVersion), data: cardInfo.card.firmwareVersion.stringValue),
        ]
        
        if let blockchain = cardInfo.defaultBlockchain?.displayName {
            data.append(EmailCollectedData(type: .card(.cardBlockchain), data: blockchain))
        }
        
        return data
    }
    
    fileprivate func formatData(_ data: [EmailCollectedData], appendDeviceInfo: Bool = true) -> String {
        data.reduce("", { $0 + $1.type.title + $1.data + "\n" }) + (appendDeviceInfo ? DeviceInfoProvider.info() : "")
    }
}

class NegativeFeedbackDataCollector: EmailDataCollector {
    
    weak var cardRepository: CardsRepository!
    
    var dataForEmail: String {
        guard let cardInfo = cardRepository.lastScanResult.cardModel?.cardInfo else { return "" }
        
        return formatData(collectData(from: cardInfo))
    }
}


struct SendScreenDataCollector: EmailDataCollector {
    
    unowned var sendViewModel: SendViewModel
    
    var lastError: Error? = nil
    
    var dataForEmail: String {
        let cardInfo = sendViewModel.cardViewModel.cardInfo
        var data = collectData(from: cardInfo)
        data.append(.separator(.dashes))
        switch sendViewModel.amountToSend.type {
        case .coin:
            data.append(EmailCollectedData(type: .card(.blockchain), data: sendViewModel.amountToSend.currencySymbol))
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        default:
            break
        }
        
        let walletPublicKey = sendViewModel.walletModel.wallet.publicKey.seedKey
        let cardWallet = cardInfo.card.wallets[walletPublicKey]

        if let signedHashesDescription = cardWallet?.totalSignedHashes?.description {
            data.append(EmailCollectedData(type: .wallet(.signedHashes), data: signedHashesDescription))
        }
        
        data.append(EmailCollectedData(type: .wallet(.walletManagerHost), data: sendViewModel.walletModel.walletManager.currentHost))
        
        if let outputsDescription = sendViewModel.walletModel.walletManager.outputsCount?.description {
            data.append(EmailCollectedData(type: .wallet(.outputsCount), data: outputsDescription))
        }
        
        if let errorDescription = self.lastError?.localizedDescription {
            data.append(EmailCollectedData(type: .error, data: errorDescription))
        }
        
        data.append(.separator(.dashes))
        
        data.append(contentsOf: [
            EmailCollectedData(type: .send(.sourceAddress), data: sendViewModel.walletModel.wallet.address),
            EmailCollectedData(type: .send(.destinationAddress), data: sendViewModel.destination),
            EmailCollectedData(type: .send(.amount), data: sendViewModel.amountText),
            EmailCollectedData(type: .send(.fee), data: sendViewModel.sendFee),
        ])
        
        if let txHex = self.txHex {
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
}

struct PushScreenDataCollector: EmailDataCollector {
    
    unowned var pushTxViewModel: PushTxViewModel
    
    var lastError: Error? = nil
    
    var dataForEmail: String {
        let cardInfo = pushTxViewModel.cardViewModel.cardInfo
        var data = collectData(from: cardInfo)
        data.append(.separator(.dashes))
        switch pushTxViewModel.amountToSend.type {
        case .coin:
            data.append(EmailCollectedData(type: .card(.blockchain), data: pushTxViewModel.amountToSend.currencySymbol))
        case .token(let token):
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        default:
            break
        }
        
        data.append(contentsOf: [
            EmailCollectedData(type: .wallet(.walletManagerHost), data: pushTxViewModel.walletModel.walletManager.currentHost),
            EmailCollectedData(type: .error, data: lastError?.localizedDescription ?? "Unknown error"),
            .separator(.dashes),
            EmailCollectedData(type: .send(.pushingTxHash), data: pushTxViewModel.transaction.hash ?? .unknown),
            EmailCollectedData(type: .send(.pushingFee), data: pushTxViewModel.selectedFee?.description ?? .unknown),
            EmailCollectedData(type: .send(.sourceAddress), data: pushTxViewModel.transaction.sourceAddress),
            EmailCollectedData(type: .send(.destinationAddress), data: pushTxViewModel.transaction.destinationAddress),
            EmailCollectedData(type: .send(.amount), data: pushTxViewModel.amount),
            EmailCollectedData(type: .send(.fee), data: pushTxViewModel.newFee),
        ])
        
        return formatData(data)
    }
    
}

struct DetailsFeedbackDataCollector: EmailDataCollector {
    
    unowned var cardModel: CardViewModel
    
    var dataForEmail: String {
        let cardInfo = cardModel.cardInfo
        
        var dataToFormat = collectData(from: cardInfo)
        let signedHashesConsolidated = cardInfo.card.wallets.map { " \($0.curve.rawValue) - \($0.totalSignedHashes ?? 0)" }.joined(separator: ";")
        dataToFormat.append(EmailCollectedData(type: .wallet(.signedHashes), data: "\(signedHashesConsolidated)"))
        
        if case let .loaded(walletModels) = cardModel.state {
            for walletModel in walletModels {
                dataToFormat.append(.separator(.dashes))
                dataToFormat.append(EmailCollectedData(type: .card(.blockchain), data: walletModel.wallet.blockchain.displayName))
                
                let tokens = walletModel.wallet.amounts.keys.compactMap ({ $0.token })
                if !tokens.isEmpty {
                    dataToFormat.append(EmailCollectedData(type: .token(.tokens), data: ""))
                }
                
                for token in tokens {
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
        }
        return formatData(dataToFormat)
    }
}
