//
//  SendCoordinator.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk

class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel?
    @Published var qrScanViewModel: QRScanViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = SendViewModel(
            walletModel: options.walletModel,
            transactionSigner: options.transactionSigner,
            sendType: options.type,
            emailDataProvider: options.emailDataProvider,
            coordinator: self
        )
    }
}

// MARK: - Options

extension SendCoordinator {
    struct Options {
        let emailDataProvider: EmailDataProvider
        let walletModel: WalletModel
        let transactionSigner: TransactionSigner
        let type: SendType
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }

    func explore(url: URL) {
        modalWebViewModel = WebViewContainerViewModel(url: url, title: Localization.commonExplorer, withCloseButton: true)
    }

    func share(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {
        let text = Localization.sendQrcodeScanInfo(networkName)
        qrScanViewModel = .init(code: codeBinding, text: text)
    }
}
