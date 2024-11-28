//
//  CardInteractor.swift
//  TangemVisa
//
//  Created by Andrew Son on 22.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol CardSetupHandler {
    func setupCard(accessCode: String, in session: CardSession) async throws
    func cancelCardSetup()
}

final class CommonCardSetupHandler {
    private let cardActivationInput: VisaCardActivationInput

    private let logger: InternalLogger

    private var isCardSetupCancelled: Bool = false

    init(
        cardActivationInput: VisaCardActivationInput,
        logger: InternalLogger
    ) {
        self.cardActivationInput = cardActivationInput
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardSetupHandler, message())
    }
}

extension CommonCardSetupHandler: CardSetupHandler {
    func setupCard(accessCode: String, in session: CardSession) async throws {
        // TODO: IOS-8569
    }

    func cancelCardSetup() {
        isCardSetupCancelled = true
    }
}

private extension CommonCardSetupHandler {
    private func createWallet(accessCode: String, in session: CardSession, on card: Card) async throws {
        if isCardSetupCancelled {
            log("Card setup was cancelled before wallet creation")
            return
        }

        let utils = VisaUtilities(isTestnet: false)
        if card.wallets.contains(where: { $0.curve == utils.mandatoryCurve }) {
            log("Wallet with \(utils.mandatoryCurve.rawValue) already created skipping wallet creation command")
            try await createOTP(accessCode: accessCode, in: session, on: card)
            return
        }

        let createWalletTask = CreateWalletTask(curve: utils.mandatoryCurve)
        _ = try await createWalletTask.run(in: session)
        log("Wallet successfully created. Start generating OTP")

        try await createOTP(accessCode: accessCode, in: session, on: card)
    }

    private func createOTP(accessCode: String, in session: CardSession, on card: Card) async throws {
        // TODO: IOS-8571
    }
}
