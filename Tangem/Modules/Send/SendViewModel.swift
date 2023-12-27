//
//  SendViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import AVFoundation

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: SendStep
    @Published var currentStepInvalid: Bool = false
    @Published var alert: AlertBinder?
    @Published var showCameraDeniedAlert = false

    var title: String? {
        step.name
    }

    var showNavigationButtons: Bool {
        step.hasNavigationButtons
    }

    var showBackButton: Bool {
        previousStep != nil
    }

    var showNextButton: Bool {
        nextStep != nil
    }

    var showQRCodeButton: Bool {
        switch step {
        case .destination:
            return true
        case .amount, .fee, .summary, .finish:
            return false
        }
    }

    let sendAmountViewModel: SendAmountViewModel
    let sendDestinationViewModel: SendDestinationViewModel
    let sendFeeViewModel: SendFeeViewModel
    let sendSummaryViewModel: SendSummaryViewModel

    // MARK: - Dependencies

    private var nextStep: SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex + 1) < steps.count
        else {
            return nil
        }

        return steps[currentStepIndex + 1]
    }

    private var previousStep: SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex - 1) >= 0
        else {
            return nil
        }

        return steps[currentStepIndex - 1]
    }

    private let sendModel: SendModel
    private let sendType: SendType
    private let walletModel: WalletModel
    private let steps: [SendStep]

    private unowned let coordinator: SendRoutable

    private var bag: Set<AnyCancellable> = []

    private var currentStepValid: AnyPublisher<Bool, Never> {
        $step
            .flatMap { [weak self] step -> AnyPublisher<Bool, Never> in
                guard let self else {
                    return .just(output: true)
                }

                switch step {
                case .amount:
                    return sendModel.amountValid
                case .destination:
                    return sendModel.destinationValid
                case .fee:
                    return sendModel.feeValid
                case .summary, .finish:
                    return .just(output: true)
                }
            }
            .eraseToAnyPublisher()
    }

    init(walletModel: WalletModel, transactionSigner: TransactionSigner, sendType: SendType, coordinator: SendRoutable) {
        self.coordinator = coordinator
        self.sendType = sendType
        self.walletModel = walletModel
        sendModel = SendModel(walletModel: walletModel, transactionSigner: transactionSigner, sendType: sendType)

        let steps = sendType.steps
        guard let firstStep = steps.first else {
            fatalError("No steps provided for the send type")
        }
        self.steps = steps
        step = firstStep

        #warning("TODO: use userwalletmodel")
        let walletName = "Wallet Name"
        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let walletInfo = SendWalletInfo(
            walletName: walletName,
            balance: walletModel.balance,
            tokenIconInfo: tokenIconInfo,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            amountFractionDigits: walletModel.tokenItem.decimalCount
        )

        sendAmountViewModel = SendAmountViewModel(input: sendModel, walletInfo: walletInfo)
        sendDestinationViewModel = SendDestinationViewModel(input: sendModel)
        sendFeeViewModel = SendFeeViewModel(input: sendModel)
        sendSummaryViewModel = SendSummaryViewModel(input: sendModel)

        sendAmountViewModel.delegate = self
        sendDestinationViewModel.delegate = self
        sendSummaryViewModel.router = self

        bind()
    }

    func next() {
        guard let nextStep else {
            assertionFailure("Invalid step logic -- next")
            return
        }

        step = nextStep
    }

    func back() {
        guard let previousStep else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        step = previousStep
    }

    func scanQRCode() {
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            let binding = Binding<String>(
                get: {
                    ""
                },
                set: { [weak self] in
                    self?.parseQRCode($0)
                }
            )

            let networkName = walletModel.blockchainNetwork.blockchain.displayName
            coordinator.openQRScanner(with: binding, networkName: networkName)
        }
    }

    private func bind() {
        currentStepValid
            .map {
                !$0
            }
            .assign(to: \.currentStepInvalid, on: self, ownership: .weak)
            .store(in: &bag)

        sendModel
            .transactionFinished
            .sink { [weak self] transactionFinished in
                if transactionFinished {
                    self?.openFinishPage()
                }
            }
            .store(in: &bag)
    }

    private func openFinishPage() {
        guard let sendFinishViewModel = SendFinishViewModel(input: sendModel) else {
            assertionFailure("WHY?")
            return
        }

        sendFinishViewModel.router = coordinator
        openStep(.finish(model: sendFinishViewModel))
    }

    private func parseQRCode(_ code: String) {
        #warning("TODO: Add the necessary UI warnings")
        let parser = QRCodeParser(amountType: walletModel.amountType, blockchain: walletModel.blockchainNetwork.blockchain)
        let result = parser.parse(code)

        sendModel.setDestination(result.destination)
        sendModel.setAmount(result.amount)
    }
}

extension SendViewModel: SendSummaryRoutable {
    func openStep(_ step: SendStep) {
        self.step = step
    }

    func send() {
        sendModel.send()
    }
}

extension SendViewModel: SendAmountViewModelDelegate {
    func didTapMaxAmount() {
        sendModel.useMaxAmount()
    }
}

extension SendViewModel: SendDestinationViewDelegate {
    func didEnterAddress(_ address: String) {
        sendModel.setDestination(address)
    }

    func didEnterAdditionalField(_ additionalField: String) {
        sendModel.setDestinationAdditionalField(additionalField)
    }

    func didSelectSuggestedDestination(_ destination: SendSuggestedDestination) {
        sendModel.setDestination(destination.address)
        if let additionalField = destination.additionalField {
            sendModel.setDestinationAdditionalField(additionalField)
        }

        #warning("TODO: ALERT THE USER")
        alert = AlertBuilder.makeSuccessAlert(message: "Address copied")
    }
}
