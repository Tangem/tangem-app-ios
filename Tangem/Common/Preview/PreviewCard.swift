//
//  PreviewCard.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk

enum PreviewCard {
    case withoutWallet
    case twin
    case ethereum
    case stellar
    case v4
    case cardanoNote
    case cardanoNoteEmptyWallet
    case ethEmptyNote
    case tangemWalletEmpty
    case tangemWalletBackuped

    var userWalletModel: CommonUserWalletModel {
        let card = CardDTO(card: card)
        let ci = CardInfo(card: card, walletData: walletData, name: "Name")
        let vm = CommonUserWalletModelFactory().makeModel(cardInfo: ci)!
        if let blockchain = blockchain {
            let factory = WalletManagerFactory(
                config: .init(
                    blockchairApiKeys: [],
                    blockcypherTokens: [],
                    infuraProjectId: "",
                    nowNodesApiKey: "",
                    getBlockCredentials: .init(credentials: []),
                    kaspaSecondaryApiUrl: nil,
                    tronGridApiKey: "",
                    hederaArkhiaApiKey: "",
                    polygonScanApiKey: "",
                    koinosProApiKey: "",
                    tonCenterApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
                    fireAcademyApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
                    chiaTangemApiKeys: .init(mainnetApiKey: ""),
                    quickNodeSolanaCredentials: .init(apiKey: "", subdomain: ""),
                    quickNodeBscCredentials: .init(apiKey: "", subdomain: ""),
                    bittensorDwellirKey: "",
                    bittensorOnfinalityKey: ""
                ),
                dependencies: .init(
                    accountCreator: BlockchainAccountCreatorStub(),
                    dataStorage: FakeBlockchainDataStorage()
                ),
                apiList: [:]
            )
            // TODO: Inject preview models into CommonUserWalletModel
            _ = try! factory.makeWalletManager(
                blockchain: blockchain,
                publicKey: .init(seedKey: publicKey, derivationType: .none)
            )
        }
        return vm
    }

    var walletData: DefaultWalletData {
        switch self {
        case .ethereum:
            return .legacy(WalletData(blockchain: "ETH", token: nil))
        case .stellar:
            return .legacy(WalletData(blockchain: "XLM", token: nil))
        case .cardanoNote:
            return .file(WalletData(blockchain: "ADA", token: nil))
        case .ethEmptyNote:
            return .file(WalletData(blockchain: "ETH", token: nil))
        case .cardanoNoteEmptyWallet:
            return .file(WalletData(blockchain: "ADA", token: nil))
        case .twin:
            return .twin(WalletData(blockchain: "BTC", token: nil), TwinData(series: .cb64, pairPublicKey: nil))
        default:
            return .none
        }
    }

    var blockchain: Blockchain? {
        switch self {
        case .ethereum:
            return .ethereum(testnet: false)
        case .stellar:
            return .stellar(curve: .ed25519_slip0010, testnet: false)
        case .cardanoNote:
            return .cardano(extended: false)
        default:
            return nil
        }
    }

    var blockchainNetwork: BlockchainNetwork? {
        blockchain.map { BlockchainNetwork($0, derivationPath: nil) }
    }

    var publicKey: Data {
        // TODO: specify other keys
        switch self {
        default:
            return Data(count: 32)
        }
    }

    var isNote: Bool {
        switch self {
        case .cardanoNote, .ethEmptyNote, .cardanoNoteEmptyWallet:
            return true
        default:
            return false
        }
    }

    private var card: Card {
        switch self {
        case .tangemWalletBackuped:
            return CardMock.wallet.card
        default:
            return CardMock.wallet2.card
        }
    }
}
