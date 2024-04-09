//
//  CardInitializer.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemSdk

protocol CardInitializable {
    var shouldReset: Bool { get set }
    func initializeCard(mnemonic: Mnemonic?, passphrase: String?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void)
}

class CardInitializer {
    var shouldReset: Bool = false

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
    func initializeCard(mnemonic: Mnemonic?, passphrase: String?, completion: @escaping (Result<CardInfo, TangemSdkError>) -> Void) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let task = PreparePrimaryCardTask(curves: config.mandatoryCurves, mnemonic: mnemonic, passphrase: passphrase, shouldReset: shouldReset)
        let initialMessage = Message(header: nil, body: Localization.initialMessageCreateWalletBody)
        runnableBag = task

        // Ring onboarding. Set custom image
        if let customOnboardingImage = config.customScanImage {
            tangemSdk.config.style.scanTagImage = .image(uiImage: customOnboardingImage.uiImage, verticalOffset: 0)
        }

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
            self?.runnableBag = nil
            self?.cancellable = nil

            // Ring onboarding. Reset the image
            self?.tangemSdk.config.style.scanTagImage = .genericCard

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
