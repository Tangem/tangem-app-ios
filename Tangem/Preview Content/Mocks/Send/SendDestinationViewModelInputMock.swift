//
//  SendDestinationViewModelInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendDestinationViewModelInputMock: SendDestinationViewModelInput {
    var destinationValid: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    var isValidatingDestination: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var destinationTextPublisher: AnyPublisher<String, Never> {
        .just(output: "0x123123")
    }

    var destinationAdditionalFieldTextPublisher: AnyPublisher<String, Never> {
        .just(output: "Memo")
    }

    var destinationError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    var destinationAdditionalFieldError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    var networkName: String {
        "Ethereum"
    }

    var additionalFieldType: SendAdditionalFields? {
        .memo
    }

    var additionalFieldEmbeddedInAddress: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    var blockchainNetwork: BlockchainNetwork {
        BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
    }

    var walletPublicKey: Wallet.PublicKey {
        .init(seedKey: Data(), derivationType: nil)
    }

    var currencySymbol: String {
        "ETH"
    }

    var walletAddresses: [String] {
        []
    }

    var transactionHistoryPublisher: AnyPublisher<WalletModel.TransactionHistoryState, Never> {
        .just(output: .loading)
    }

    var suggestedWallets: [SendSuggestedDestinationWallet] {
        []
    }

    func setDestination(_ address: SendAddress) {}
    func setDestinationAdditionalField(_ additionalField: String) {}
}
