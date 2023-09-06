//
//  LegacySendCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 16.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

class LegacySendCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var sendViewModel: LegacySendViewModel? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil
    @Published var qrScanViewModel: QRScanViewModel? = nil

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: LegacySendCoordinator.Options) {
        if let destination = options.destination {
            sendViewModel = LegacySendViewModel(
                amountToSend: options.amountToSend,
                destination: destination,
                blockchainNetwork: options.blockchainNetwork,
                cardViewModel: options.cardViewModel,
                coordinator: self
            )
        } else {
            sendViewModel = LegacySendViewModel(
                amountToSend: options.amountToSend,
                blockchainNetwork: options.blockchainNetwork,
                cardViewModel: options.cardViewModel,
                coordinator: self
            )
        }
    }
}

extension LegacySendCoordinator {
    struct Options {
        let amountToSend: Amount
        let destination: String?
        let blockchainNetwork: BlockchainNetwork
        let cardViewModel: CardViewModel
    }
}

extension LegacySendCoordinator: LegacySendRoutable {
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }

    func closeModule() {
        dismiss()
    }

    func openQRScanner(with codeBinding: Binding<String>) {
        qrScanViewModel = .init(code: codeBinding)
    }
}
