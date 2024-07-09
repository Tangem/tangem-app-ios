//
//  SendStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

protocol SendStep {
    var title: String? { get }
    var subtitle: String? { get }

    var type: SendStepType { get }
    var viewType: SendStepViewType { get }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { get }

    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool

    func willAppear(previous step: any SendStep)
    func didAppear()

    func willDisappear(next step: any SendStep)
    func didDisappear()
}

extension SendStep {
    var subtitle: String? { .none }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .none }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        return true
    }

    func willAppear(previous step: any SendStep) {}
    func didAppear() {}

    func willDisappear(next step: any SendStep) {}
    func didDisappear() {}
}

enum SendStepType: String, Hashable {
    case destination
    case amount
    case fee
    case summary
    case finish
}

enum SendStepViewType {
    case destination(SendDestinationViewModel)
    case amount(SendAmountViewModel)
    case fee(SendFeeViewModel)
    case summary(SendSummaryViewModel)
    case finish(SendFinishViewModel)
}

enum SendStepNavigationTrailingViewType {
    case qrCodeButton(action: () -> Void)
}

extension SendStepType {
    var analyticsSourceParameterValue: Analytics.ParameterValue {
        switch self {
        case .amount:
            return .amount
        case .destination:
            return .address
        case .fee:
            return .fee
        case .summary:
            return .summary
        case .finish:
            return .finish
        }
    }
}
