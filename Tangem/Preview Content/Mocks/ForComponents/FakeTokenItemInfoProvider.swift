//
//  FakeTokenItemInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeTokenItemInfoProvider: TokenItemInfoProvider, PriceChangeProvider, ObservableObject {
    var walletStatePublisher: AnyPublisher<WalletModel.State, Never> { walletStateSubject.eraseToAnyPublisher() }
    var priceChangePublisher: AnyPublisher<Void, Never> { priceChangedSubject.eraseToAnyPublisher() }
    var pendingTransactionPublisher: AnyPublisher<(WalletModelId, Bool), Never> { pendingTransactionNotifier.eraseToAnyPublisher() }

    let walletStateSubject = CurrentValueSubject<WalletModel.State, Never>(.created)
    let pendingTransactionNotifier = PassthroughSubject<(WalletModelId, Bool), Never>()

    let priceChangedSubject = PassthroughSubject<Void, Never>()
    let blockchain = Blockchain.ethereum(testnet: false)

    private var amountsIndex = 0
    private var previouslyTappedModelId: Int?
    private var bag = Set<AnyCancellable>()

    private(set) lazy var viewModels: [TokenItemViewModel] = {
        [
            .init(
                id: makeId(for: amounts[amountsIndex][.coin]!),
                tokenIcon: coinInfo,
                tokenItem: .blockchain(blockchain),
                tokenTapped: modelTapped(with:),
                infoProvider: self,
                priceChangeProvider: self
            ),
            .init(
                id: makeId(for: amounts[amountsIndex][.token(value: wxDaiToken)]!),
                tokenIcon: makeTokenIconInfo(for: wxDaiToken),
                tokenItem: .token(wxDaiToken, blockchain),
                tokenTapped: modelTapped(with:),
                infoProvider: self,
                priceChangeProvider: self
            ),
            .init(
                id: makeId(for: amounts[amountsIndex][.token(value: tetherToken)]!),
                tokenIcon: makeTokenIconInfo(for: tetherToken),
                tokenItem: .token(tetherToken, blockchain),
                tokenTapped: modelTapped(with:),
                infoProvider: self,
                priceChangeProvider: self
            ),
        ]
    }()

    private var coinInfo: TokenIconInfo {
        TokenIconInfoBuilder()
            .build(for: .coin, in: blockchain)
    }

    private var wxDaiToken: Token {
        Token(
            name: "Wrapped XDAI",
            symbol: "WXDAI",
            contractAddress: "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d",
            decimalCount: 18,
            id: "wrapped-xdai"
        )
    }

    private var tetherToken: Token {
        Token(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
            decimalCount: 18,
            id: "tether"
        )
    }

    private lazy var amounts: [[Amount.AmountType: Amount]] = [
        [
            .coin: .init(with: .ethereum(testnet: false), value: 5),
            .token(value: wxDaiToken): .init(with: wxDaiToken, value: 150),
            .token(value: tetherToken): .init(with: tetherToken, value: 0.000005),
        ],
        [
            .coin: .init(with: .ethereum(testnet: false), value: 59),
            .token(value: wxDaiToken): .init(with: wxDaiToken, value: 10),
            .token(value: tetherToken): .init(with: tetherToken, value: 6.0000000005),
        ],
    ]

    func balance(for amountType: BlockchainSdk.Amount.AmountType) -> Decimal {
        amounts[amountsIndex][amountType]?.value ?? 0
    }

    func change(for currencyCode: String, in blockchain: BlockchainSdk.Blockchain) -> Double {
        0
    }

    func modelTapped(with id: Int) {
        if let previouslyTappedModelId = previouslyTappedModelId {
            pendingTransactionNotifier.send((previouslyTappedModelId, false))
        }

        if previouslyTappedModelId != id {
            previouslyTappedModelId = id
            pendingTransactionNotifier.send((id, true))
        } else {
            previouslyTappedModelId = nil
            walletStateSubject.send(.loading)
        }

        switch walletStateSubject.value {
        case .created:
            walletStateSubject.send(.loading)
        case .loading:
            let index = viewModels.firstIndex(where: { $0.id == id })
            switch index {
            case 0:
                amountsIndex = amountsIndex == 0 ? 1 : 0
                walletStateSubject.send(.idle)
            case 1:
                walletStateSubject.send(.failed(error: "Failed i failed, che eshe tut skazat?.."))
            default:
                walletStateSubject.send(.noDerivation)
            }
        case .idle:
            walletStateSubject.send(.loading)
        case .noDerivation:
            walletStateSubject.send(.noAccount(message: "You need to topup account to use it"))
        case .noAccount:
            walletStateSubject.send(.created)
        case .failed:
            walletStateSubject.send(.loading)
        }
    }

    private func makeTokenIconInfo(for token: Token) -> TokenIconInfo {
        return TokenIconInfoBuilder()
            .build(for: .token(value: token), in: blockchain)
    }

    private func makeId(for amount: Amount) -> Int {
        var hasher = Hasher()
        hasher.combine(amount.type)
        hasher.combine(amount.currencySymbol)
        return hasher.finalize()
    }
}
