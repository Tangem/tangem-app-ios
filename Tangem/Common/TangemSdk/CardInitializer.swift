//
//  CardInitializer.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

protocol CardInitializable {
    func initializeCard(mnemonic: Mnemonic?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void)
}

class CardInitializer {
    private let tangemSdk: TangemSdk
    private var cardInfo: CardInfo
    private var runnableBag: (any CardSessionRunnable)?
    private var cancellable: AnyCancellable?

    internal init(tangemSdk: TangemSdk, cardInfo: CardInfo) {
        self.tangemSdk = tangemSdk
        self.cardInfo = cardInfo
    }
}

extension CardInitializer: CardInitializable {
    func initializeCard(mnemonic: Mnemonic?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let task = PreparePrimaryCardTask(curves: config.mandatoryCurves, mnemonic: mnemonic)
        let initialMessage = Message(header: nil, body: Localization.initialMessageCreateWalletBody)
        runnableBag = task

        let didBecomeActivePublisher = NotificationCenter.didBecomeActivePublisher
            .mapError { $0.toTangemSdkError() }
            .mapVoid()
            .first()

        cancellable = tangemSdk.startSessionPublisher(
            with: task,
            cardId: cardInfo.card.cardId,
            initialMessage: initialMessage
        )
        .combineLatest(didBecomeActivePublisher)
        .map { [cardInfo] response, _ -> CardInfo in
            var mutableCardInfo = cardInfo
            mutableCardInfo.card = CardDTO(card: response.card)
            mutableCardInfo.primaryCard = response.primaryCard
            return mutableCardInfo
        }
        .sink(receiveCompletion: { [weak self] completionResult in
            self?.runnableBag = nil
            self?.cancellable = nil

            switch completionResult {
            case .finished:
                // empty cardInfo is an impossible case
                if let cardInfo = self?.cardInfo {
                    completion(.success(cardInfo))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }, receiveValue: { [weak self] newCardInfo in
            self?.cardInfo = newCardInfo
        })
    }
}
