//
//  TwinsWalletCreationUtil.swift
//  Tangem
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

class TwinsWalletCreationUtil {
    static let twinFileName = "TwinPublicKey"

    var twinPairCardId: String?

    /// Determines is user start twin wallet creation from Twin card with first number
    var isStartedFromFirstNumber: Bool {
        twinData.series.number == 1
    }

    var stepCardNumber: Int {
        let series = twinData.series

        switch step.value {
        case .first, .third, .done:
            return series.number
        case .second:
            return series.pair.number
        }
    }

    private let twinFileEncoder: TwinCardFileEncoder = TwinCardTlvFileEncoder()
    private var firstTwinCid: String = ""
    private var twinData: TwinData

    private var firstTwinPublicKey: Data?
    private var secondTwinPublicKey: Data?

    private(set) var step = CurrentValueSubject<CreationStep, Never>(.first)
    private(set) var occuredError = PassthroughSubject<Error, Never>()
    private(set) var isServiceBusy = CurrentValueSubject<Bool, Never>(false)
    private let sdk: TangemSdk = TwinTangemSdkFactory(isAccessCodeSet: false).makeTangemSdk()

    init(cardId: String, twinData: TwinData) {
        self.twinData = twinData
        firstTwinCid = cardId
    }

    func executeCurrentStep() {
        isServiceBusy.send(true)
        switch step.value {
        case .first:
            createWalletOnFirstCard()
        case .second:
            createWalletOnSecondCard()
        case .third:
            writeSecondPublicKeyToFirst()
        case .done:
            break
        }
    }

    func resetSteps() {
        step = CurrentValueSubject<CreationStep, Never>(.first)
        isServiceBusy.send(false)
    }

    private func createWalletOnFirstCard() {
        Analytics.log(.buttonCreateWallet)

        let task = TwinsCreateWalletTask(firstTwinCardId: nil, fileToWrite: nil)
        sdk.startSession(with: task, cardId: firstTwinCid, initialMessage: initialMessage(for: firstTwinCid)) { result in
            switch result {
            case .success(let response):
                self.firstTwinPublicKey = response.createWalletResponse.wallet.publicKey
                self.step.send(.second)
            case .failure(let error):
                self.occuredError.send(error)
            }
            self.isServiceBusy.send(false)
        }
    }

    private func createWalletOnSecondCard() {
        guard
            let firstTwinKey = firstTwinPublicKey,
            let series = TwinCardSeries.series(for: firstTwinCid)
        else {
            step.send(.first)
            occuredError.send(TangemSdkError.missingIssuerPublicKey)
            return
        }

        let task = TwinsCreateWalletTask(firstTwinCardId: firstTwinCid, fileToWrite: firstTwinKey)
        sdk.startSession(with: task, initialMessage: Message(header: "Scan card #\(series.pair.number)")) { result in
            switch result {
            case .success(let response):
                self.secondTwinPublicKey = response.createWalletResponse.wallet.publicKey
                self.twinPairCardId = response.createWalletResponse.cardId
                self.step.send(.third)
            case .failure(let error):
                self.occuredError.send(error)
            }
            self.isServiceBusy.send(false)
        }
    }

    private func writeSecondPublicKeyToFirst() {
        guard let secondTwinKey = secondTwinPublicKey else {
            step.send(.second)
            occuredError.send(TangemSdkError.missingIssuerPublicKey)
            return
        }

        let task = TwinsFinalizeWalletCreationTask(fileToWrite: secondTwinKey)
        sdk.startSession(with: task, cardId: firstTwinCid, initialMessage: initialMessage(for: firstTwinCid)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                Analytics.log(.walletCreatedSuccessfully, params: [.creationType: .walletCreationTypePrivateKey])

                step.send(.done(response.getCardInfo()))
            case .failure(let error):
                occuredError.send(error)
            }
            isServiceBusy.send(false)
        }
    }

    private func twinFileToWrite(publicKey: Data) -> Result<Data, Error> {
        do {
            let data = try twinFileEncoder.encode(TwinCardFile(publicKey: publicKey, fileTypeName: TwinsWalletCreationUtil.twinFileName))
            return .success(data)
        } catch {
            AppLog.shared.error(error)
            return .failure(error)
        }
    }

    private func initialMessage(for cardId: String) -> Message {
        let formatted = AppTwinCardIdFormatter.format(cid: cardId, cardNumber: stepCardNumber)
        let header = Localization.twinsScanTwinWithNumber(formatted)
        return Message(header: header)
    }
}

extension TwinsWalletCreationUtil {
    enum CreationStep {
        case first
        case second
        case third
        case done(CardInfo)
    }
}
