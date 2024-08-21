//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 03.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendFinishViewModelSetupable: AnyObject {
    func setup(sendFinishInput: SendFinishInput)
    func setup(sendDestinationInput: SendDestinationInput)
    func setup(sendAmountInput: SendAmountInput)
    func setup(sendFeeInput: SendFeeInput)
}

class SendFinishViewModel: ObservableObject, Identifiable {
    @Published var showHeader = false
    @Published var transactionSentTime: String?
    @Published var alert: AlertBinder?

    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: SendAmountSummaryViewData?
    @Published var selectedValidatorData: ValidatorViewData?
    @Published var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?

    let addressTextViewHeightModel: AddressTextViewHeightModel?

    private let tokenItem: TokenItem
    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder

    private var feeTypeAnalyticsParameter: Analytics.ParameterValue = .null
    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        addressTextViewHeightModel: AddressTextViewHeightModel?,
        sectionViewModelFactory: SendSummarySectionViewModelFactory,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    ) {
        tokenItem = settings.tokenItem

        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.sectionViewModelFactory = sectionViewModelFactory
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
    }

    func onAppear() {
        Analytics.log(event: .sendTransactionSentScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])

        withAnimation(SendView.Constants.defaultAnimation) {
            showHeader = true
        }
    }
}

// MARK: - SendFinishViewModelSetupable

extension SendFinishViewModel: SendFinishViewModelSetupable {
    func setup(sendDestinationInput input: SendDestinationInput) {
        Publishers.CombineLatest(input.destinationPublisher, input.additionalFieldPublisher)
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (destination, additionalField) = args
                return viewModel.sectionViewModelFactory.makeDestinationViewTypes(
                    address: destination.value,
                    additionalField: additionalField
                )
            }
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)
    }

    func setup(sendAmountInput input: SendAmountInput) {
        input.amountPublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, amount in
                guard let formattedAmount = amount?.format(currencySymbol: viewModel.tokenItem.currencySymbol, decimalCount: viewModel.tokenItem.decimalCount),
                      let formattedAlternativeAmount = amount?.formatAlternative(currencySymbol: viewModel.tokenItem.currencySymbol, decimalCount: viewModel.tokenItem.decimalCount) else {
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

    func setup(sendFeeInput input: SendFeeInput) {
        input.selectedFeePublisher
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.feeTypeAnalyticsParameter = viewModel.feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee.option)
                viewModel.selectedFeeSummaryViewModel = viewModel.sectionViewModelFactory.makeFeeViewData(from: selectedFee)
            }
            .store(in: &bag)
    }

    func setup(sendFinishInput input: any SendFinishInput) {
        input.transactionSentDate
            .map { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] time in
                withAnimation(SendView.Constants.defaultAnimation) {
                    self?.transactionSentTime = time
                }
            })
            .store(in: &bag)
    }
}

extension SendFinishViewModel {
    struct Settings {
        let tokenItem: TokenItem
    }
}
