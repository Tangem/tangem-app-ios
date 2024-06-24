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

protocol SendSummaryInteractor: AnyObject {
    var isSending: AnyPublisher<Bool, Never> { get }
}

protocol SendSummaryInput: AnyObject {
    var isSending: Bool { get }
}

protocol SendSummaryOutput: AnyObject {}

protocol SendSummaryViewModelSetupable: AnyObject {
    func setup(sendDestinationInput: SendDestinationInput)
    func setup(sendAmountInput: SendAmountInput)
    func setup(sendFeeInteractor: SendFeeInteractor)
}

protocol SendSummaryViewModelInput: AnyObject {
//    var canEditAmount: Bool { get }
//    var canEditDestination: Bool { get }

//    var amountPublisher: AnyPublisher<SendAmount?, Never> { get }
//    var destinationTextPublisher: AnyPublisher<String, Never> { get }
//    var additionalFieldPublisher: AnyPublisher<DestinationAdditionalFieldType, Never> { get }
//    var selectedFeePublisher: AnyPublisher<SendFee?, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }
}

class SendSummaryViewModel: ObservableObject {
    @Published var canEditAmount: Bool
    @Published var canEditDestination: Bool
    @Published var canEditFee: Bool = true

//    var walletName: String {
//        walletInfo.walletName
//    }

//    var balance: String {
//        walletInfo.balance
//    }

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

    let addressTextViewHeightModel: AddressTextViewHeightModel
    var didProperlyDisappear: Bool = true

    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    private let tokenItem: TokenItem
    private let interactor: SendSummaryInteractor
    private let notificationManager: SendNotificationManager
    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    weak var router: SendSummaryRoutable?

    private var isVisible = false
    private var bag: Set<AnyCancellable> = []

    init(
        initial: Initial,
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sectionViewModelFactory: SendSummarySectionViewModelFactory
    ) {
        canEditDestination = initial.canEditDestination
        canEditAmount = initial.canEditAmount
        tokenItem = initial.tokenItem

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.sectionViewModelFactory = sectionViewModelFactory

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
        interactor
            .isSending
            .assign(to: \.isSending, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .summary)
            .sink { [weak self] notificationInputs in
                self?.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }
}

// MARK: - SendSummaryViewModelSetupable

extension SendSummaryViewModel: SendSummaryViewModelSetupable {
    func setup(sendDestinationInput input: SendDestinationInput) {
        Publishers.CombineLatest(input.destinationTextPublisher(), input.additionalFieldPublisher())
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (destination, additionalField) = args
                return viewModel.sectionViewModelFactory.makeDestinationViewTypes(
                    address: destination,
                    additionalField: additionalField
                )
            }
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)
    }

    func setup(sendAmountInput input: SendAmountInput) {
        input.amountPublisher()
            .withWeakCaptureOf(self)
            .compactMap { viewModel, amount in
                guard let formattedAmount = amount?.format(currencySymbol: viewModel.tokenItem.currencySymbol),
                      let formattedAlternativeAmount = amount?.formatAlternative(currencySymbol: viewModel.tokenItem.currencySymbol) else {
                    return nil
                }

                return viewModel.sectionViewModelFactory.makeAmountViewData(
                    amount: formattedAmount,
                    amountAlternative: formattedAlternativeAmount
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.amountSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func setup(sendFeeInteractor interactor: SendFeeInteractor) {
        interactor
            .feesPublisher()
            .map { feeValues in
                let multipleFeeOptions = feeValues.count > 1
                let hasError = feeValues.contains { $0.value.error != nil }

                return multipleFeeOptions && !hasError
            }
            .assign(to: \.canEditFee, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(interactor.feesPublisher(), interactor.selectedFeePublisher())
            .withWeakCaptureOf(self)
            .sink { viewModel, args in
                let (feeValues, selectedFee) = args
                var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
                var deselectedFeeRowViewModels: [FeeRowViewModel] = []

                for feeValue in feeValues {
                    if feeValue.option == selectedFee?.option {
                        selectedFeeSummaryViewModel = viewModel.sectionViewModelFactory.makeFeeViewData(from: feeValue)
                    } else {
                        let model = viewModel.sectionViewModelFactory.makeDeselectedFeeRowViewModel(from: feeValue)
                        deselectedFeeRowViewModels.append(model)
                    }
                }

                viewModel.selectedFeeSummaryViewModel = selectedFeeSummaryViewModel
                viewModel.deselectedFeeRowViewModels = deselectedFeeRowViewModels
            }
            .store(in: &bag)
    }
}

extension SendSummaryViewModel {
    struct Initial {
        let tokenItem: TokenItem
        let canEditAmount: Bool
        let canEditDestination: Bool
    }
}
