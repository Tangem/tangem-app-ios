//
//  CommonCardInitializer.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.05.2023.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemSdk

class CommonCardInitializer {
    var shouldReset: Bool = false

    private let tangemSdk: TangemSdk
    private var cardInfo: CardInfo
    private var cancellable: AnyCancellable?

    init(tangemSdk: TangemSdk, cardInfo: CardInfo) {
        self.tangemSdk = tangemSdk
        self.cardInfo = cardInfo
    }
}

extension CommonCardInitializer: CardInitializer {
    func initializeCard(mnemonic: Mnemonic?, passphrase: String?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let task = PreparePrimaryCardTask(curves: config.createWalletCurves, mnemonic: mnemonic, passphrase: passphrase, shouldReset: shouldReset)

        let isRing = RingUtil().isRing(batchId: cardInfo.card.batchId)

        let initialMessage = Message(
            header: nil,
            body: isRing ? Localization.initialMessageCreateWalletBodyRing : Localization.initialMessageCreateWalletBody
        )

        // Ring onboarding. Set custom image
        tangemSdk.config.setupForProduct(isRing ? .ring : .card)

        let didBecomeActivePublisher = NotificationCenter.didBecomeActivePublisher
            .mapError { $0.toTangemSdkError() }
            .mapToVoid()
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
            mutableCardInfo.card.attestation = cardInfo.card.attestation
            return mutableCardInfo
        }
        .sink(receiveCompletion: { [weak self] completionResult in
            // Ring onboarding. Reset the image
            self?.tangemSdk.config.setupForProduct(.any)

            switch completionResult {
            case .finished:
                // empty cardInfo is an impossible case
                if let cardInfo = self?.cardInfo {
                    completion(.success(cardInfo))
                }
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(task) {}
            self?.cancellable = nil
        }, receiveValue: { [weak self] newCardInfo in
            self?.cardInfo = newCardInfo
        })
    }
}
