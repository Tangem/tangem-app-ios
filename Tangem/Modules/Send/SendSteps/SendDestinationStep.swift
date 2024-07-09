//
//  SendDestinationStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

protocol SendQRCodeService {
    func qrCodeDidScanned(result: QRCodeParser.Result)
}

class SendDestinationStep {
    private let viewModel: SendDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let sendAmountViewModel: SendAmountViewModel
    private let sendFeeInteractor: SendFeeInteractor
    private let tokenItem: TokenItem
    private weak var router: SendDestinationRoutable?

    var auxiliaryViewAnimatable: AuxiliaryViewAnimatable {
        viewModel
    }

    init(
        viewModel: SendDestinationViewModel,
        interactor: any SendDestinationInteractor,
        sendAmountViewModel: SendAmountViewModel,
        sendFeeInteractor: any SendFeeInteractor,
        tokenItem: TokenItem,
        router: any SendDestinationRoutable
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendAmountViewModel = sendAmountViewModel
        self.sendFeeInteractor = sendFeeInteractor
        self.tokenItem = tokenItem
        self.router = router
    }

    private func scanQRCode() {
        let binding = Binding<String>(get: { "" }, set: parseQRCode)

        let networkName = tokenItem.blockchain.displayName
        router?.openQRScanner(with: binding, networkName: networkName)
    }

    private func parseQRCode(_ code: String) {
        // TODO: Add the necessary UI warnings
        let parser = QRCodeParser(
            amountType: tokenItem.amountType,
            blockchain: tokenItem.blockchain,
            decimalCount: tokenItem.decimalCount
        )

        guard let result = parser.parse(code) else {
            return
        }

        viewModel.setExternally(address: SendAddress(value: result.destination, source: .qrCode), additionalField: result.memo)

        if let amount = result.amount?.value {
            sendAmountViewModel.setExternalAmount(amount)
        }
    }
}

// MARK: - SendStep

extension SendDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .destination }

    var viewType: SendStepViewType { .destination(viewModel) }

    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .qrCodeButton(action: scanQRCode) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.destinationValid.eraseToAnyPublisher()
    }

    func willDisappear(next step: SendStep) {
        guard step.type == .summary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
