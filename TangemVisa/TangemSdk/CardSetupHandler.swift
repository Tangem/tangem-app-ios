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
