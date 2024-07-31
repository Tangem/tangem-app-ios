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
    private let notificationManager: NotificationManager
    private let tokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder

    // We have to use this `SendViewAlertPresenter`
    // Because .alert(item:) doesn't work in the nested views
    private weak var alertPresenter: SendViewAlertPresenter?

    init(
        viewModel: SendFeeViewModel,
        interactor: SendFeeInteractor,
        notificationManager: NotificationManager,
        tokenItem: TokenItem,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.tokenItem = tokenItem
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
    }

    func set(alertPresenter: SendViewAlertPresenter) {
        self.alertPresenter = alertPresenter
    }
}

// MARK: - SendStep

extension SendFeeStep: SendStep {
    var title: String? { Localization.commonFeeSelectorTitle }

    var type: SendStepType { .fee(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
        for event in events {
            switch event {
            case .customFeeTooLow:
                Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
                    .token: tokenItem.currencySymbol,
                ])

                alertPresenter?.showAlert(
                    SendAlertBuilder.makeCustomFeeTooLowAlert(continueAction: continueAction)
                )

                return false
            case .customFeeTooHigh(let orderOfMagnitude):
                alertPresenter?.showAlert(
                    SendAlertBuilder.makeCustomFeeTooHighAlert(orderOfMagnitude, continueAction: continueAction)
                )

                return false
            default:
                break
            }
        }

        return true
    }

    func willAppear(previous step: any SendStep) {
        if step.type.isSummary {
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        } else {
            Analytics.log(.sendFeeScreenOpened)
        }

        interactor.updateFees()
    }

    func willDisappear(next step: SendStep) {
        UIApplication.shared.endEditing()

        // We have to send this event when user move on the next step
        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: interactor.selectedFee?.option)
        Analytics.log(event: .sendFeeSelected, params: [.feeType: feeType.rawValue])
    }
}
