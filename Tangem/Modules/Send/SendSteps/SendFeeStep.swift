//
//  SendFeeStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendFeeStep {
    private let viewModel: SendFeeViewModel
    private let interactor: SendFeeInteractor
    private let notificationManager: SendNotificationManager
    private let tokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder

    init(
        viewModel: SendFeeViewModel,
        interactor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        tokenItem: TokenItem,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.tokenItem = tokenItem
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
    }
}

// MARK: - SendStep

extension SendFeeStep: SendStep {
    var title: String? { Localization.commonFeeSelectorTitle }

    var type: SendStepType { .fee(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.selectedFeePublisher.map { $0 != nil }.eraseToAnyPublisher()
    }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
        for event in events {
            switch event {
            case .customFeeTooLow:
                Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
                    .token: tokenItem.currencySymbol,
                ])

                viewModel.alert = SendAlertBuilder.makeCustomFeeTooLowAlert(continueAction: continueAction)

                return false
            case .customFeeTooHigh(let orderOfMagnitude):
                viewModel.alert = SendAlertBuilder.makeCustomFeeTooHighAlert(orderOfMagnitude, continueAction: continueAction)

                return false
            default:
                break
            }
        }

        return true
    }

    func willAppear(previous step: any SendStep) {
        guard step.type.isSummary else {
            return
        }

        viewModel.setAnimatingAuxiliaryViewsOnAppear()
    }

    func willDisappear(next step: SendStep) {
        // We have to send this event when user move on the next step
        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: interactor.selectedFee?.option)
        Analytics.log(event: .sendFeeSelected, params: [.feeType: feeType.rawValue])
    }
}
