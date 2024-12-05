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

class SendFinishViewModel: ObservableObject, Identifiable {
    @Published var showHeader = false
    @Published var transactionSentTime: String?
    @Published var alert: AlertBinder?

    @Published var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var onrampAmountCompactViewModel: OnrampAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?
    @Published var onrampStatusCompactViewModel: OnrampStatusCompactViewModel?

    private var sendFinishAnalyticsLogger: SendFinishAnalyticsLogger
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?
    ) {
        self.sendFinishAnalyticsLogger = sendFinishAnalyticsLogger
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.onrampAmountCompactViewModel = onrampAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel
        self.onrampStatusCompactViewModel = onrampStatusCompactViewModel

        bind(input: input)
    }

    func onAppear() {
        sendFinishAnalyticsLogger.onAppear()

        withAnimation(SendTransitionService.Constants.defaultAnimation) {
            showHeader = true
        }
    }

    func bind(input: SendFinishInput) {
        input.transactionSentDate
            .map { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] time in
                withAnimation(SendTransitionService.Constants.defaultAnimation) {
                    self?.transactionSentTime = time
                }
            })
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension SendFinishViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
