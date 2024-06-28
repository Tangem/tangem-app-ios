//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendSummaryViewModelInput: AnyObject {
    var canEditAmount: Bool { get }
    var canEditDestination: Bool { get }
    var feeOptions: [FeeOption] { get }

    var amountPublisher: AnyPublisher<SendAmount?, Never> { get }
    var transactionAmountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var additionalFieldPublisher: AnyPublisher<DestinationAdditionalFieldType, Never> { get }
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
    var selectedFeeOptionPublisher: AnyPublisher<FeeOption, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }
}

class SendSummaryViewModel: ObservableObject {
    let canEditAmount: Bool
    let canEditDestination: Bool
    @Published var canEditFee: Bool = true

    var destinationBackground: Color {
        sectionBackground(canEdit: canEditDestination)
    }

    var amountBackground: Color {
        sectionBackground(canEdit: canEditAmount)
    }

    var walletName: String {
        walletInfo.walletName
    }

    var balance: String {
        walletInfo.balance
    }

    @Published var isSending = false
    @Published var alert: AlertBinder?

    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: SendAmountSummaryViewData?
    @Published var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
    @Published var deselectedFeeRowViewModels: [FeeRowViewModel] = []

    @Published var animatingDestinationOnAppear = false
    @Published var animatingAmountOnAppear = false
    @Published var animatingFeeOnAppear = false
    @Published var showHint = false

    var didProperlyDisappear: Bool = true

    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    weak var router: SendSummaryRoutable?

    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    private var bag: Set<AnyCancellable> = []
    private let input: SendSummaryViewModelInput
    private let tokenItem: TokenItem
    private let walletInfo: SendWalletInfo
    private let notificationManager: SendNotificationManager
    private var isVisible = false

    let addressTextViewHeightModel: AddressTextViewHeightModel

    init(
        initial: Initial,
        input: SendSummaryViewModelInput,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo,
        sectionViewModelFactory: SendSummarySectionViewModelFactory
    ) {
        tokenItem = initial.tokenItem

        self.input = input
        self.walletInfo = walletInfo
        self.notificationManager = notificationManager
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.sectionViewModelFactory = sectionViewModelFactory

        canEditAmount = input.canEditAmount
        canEditDestination = input.canEditDestination

        bind()
    }

    func setupAnimations(previousStep: SendStep) {
        switch previousStep {
        case .destination:
            animatingAmountOnAppear = true
            animatingFeeOnAppear = true
        case .amount:
            animatingDestinationOnAppear = true
            animatingFeeOnAppear = true
        case .fee:
            animatingDestinationOnAppear = true
            animatingAmountOnAppear = true
        default:
            break
        }

        showHint = false
    }

    func onAppear() {
        isVisible = true

        selectedFeeSummaryViewModel?.setAnimateTitleOnAppear(true)

        withAnimation(SendView.Constants.defaultAnimation) {
            self.animatingDestinationOnAppear = false
            self.animatingAmountOnAppear = false
            self.animatingFeeOnAppear = false
        }

        Analytics.log(.sendConfirmScreenOpened)

        // For the sake of simplicity we're assuming that notifications aren't going to be created after the screen has been displayed
        if notificationInputs.isEmpty, !AppSettings.shared.userDidTapSendScreenSummary {
            withAnimation(SendView.Constants.defaultAnimation.delay(SendView.Constants.animationDuration * 2)) {
                self.showHint = true
            }
        }
    }

    func onDisappear() {
        isVisible = false
    }

    func didTapSummary(for step: SendStep) {
        if isSending {
            return
        }

        AppSettings.shared.userDidTapSendScreenSummary = true
        showHint = false

        router?.openStep(step)
    }

    private func bind() {
        input
            .isSending
            .assign(to: \.isSending, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(input.destinationTextPublisher, input.additionalFieldPublisher)
            .map { [weak self] destination, additionalField in
                self?.sectionViewModelFactory.makeDestinationViewTypes(address: destination, additionalField: additionalField) ?? []
            }
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)

        input.amountPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, amount in
                let formattedAmount = amount?.format(currencySymbol: viewModel.tokenItem.currencySymbol)
                let formattedAlternativeAmount = amount?.formatAlternative(currencySymbol: viewModel.tokenItem.currencySymbol)

                return viewModel.sectionViewModelFactory.makeAmountViewData(
                    from: formattedAmount,
                    amountAlternative: formattedAlternativeAmount
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.amountSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(input.feeValues, input.selectedFeeOptionPublisher)
            .sink { [weak self] feeValues, selectedFeeOption in
                guard let self else { return }

                var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
                var deselectedFeeRowViewModels: [FeeRowViewModel] = []

                for feeOption in input.feeOptions {
                    let feeValue = feeValues[feeOption] ?? .failedToLoad(error: WalletError.failedToGetFee)

                    if feeOption == selectedFeeOption {
                        selectedFeeSummaryViewModel = sectionViewModelFactory.makeFeeViewData(
                            from: feeValue,
                            feeOption: feeOption
                        )
                    } else {
                        let model = sectionViewModelFactory.makeDeselectedFeeRowViewModel(from: feeValue, feeOption: feeOption)
                        deselectedFeeRowViewModels.append(model)
                    }
                }

                self.selectedFeeSummaryViewModel = selectedFeeSummaryViewModel
                self.deselectedFeeRowViewModels = deselectedFeeRowViewModels

                let multipleFeeOptions = input.feeOptions.count > 1
                let noFeeErrors = feeValues.allSatisfy { $0.value.error == nil }
                canEditFee = multipleFeeOptions && noFeeErrors
            }
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .summary)
            .sink { [weak self] notificationInputs in
                self?.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }

    private func sectionBackground(canEdit: Bool) -> Color {
        canEdit ? Colors.Background.action : Colors.Button.disabled
    }
}

extension SendSummaryViewModel {
    struct Initial {
        let tokenItem: TokenItem
    }
}
