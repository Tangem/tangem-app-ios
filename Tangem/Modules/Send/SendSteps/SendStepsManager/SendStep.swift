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
    associatedtype ViewModel: ObservableObject
    var viewModel: ViewModel { get }

    var type: SendStepType { get }
    var title: String? { get }
    var subtitle: String? { get }

    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func makeView(namespace: Namespace.ID) -> AnyView
    func makeNavigationTrailingView(namespace: Namespace.ID) -> AnyView
    func makeCompactView(namespace: Namespace.ID) -> AnyView

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool
    func willAppear(previous step: any SendStep)
    func willClose(next step: any SendStep)
}

extension SendStep {
    var subtitle: String? { nil }

    func makeCompactView(namespace: Namespace.ID) -> AnyView {
        AnyView(EmptyView())
    }

    func makeNavigationTrailingView(namespace: Namespace.ID) -> AnyView {
        AnyView(EmptyView())
    }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        return true
    }

    func willAppear(previous step: any SendStep) {}
    func willClose(next step: any SendStep) {}
}

enum SendStepType: String, Hashable {
    case destination
    case amount
    case fee
    case summary
    case finish
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

    // TODO: Will be removed https://tangem.atlassian.net/browse/IOS-7195
    struct Parameters {
        let currencyName: String
        let walletName: String
    }

    func name(for parameters: Parameters) -> String? {
        switch self {
        case .amount:
            return Localization.sendAmountLabel
        case .destination:
            return Localization.sendRecipientLabel
        case .fee:
            return Localization.commonFeeSelectorTitle
        case .summary:
            return Localization.sendSummaryTitle(parameters.currencyName)
        case .finish:
            return nil
        }
    }

    func description(for parameters: Parameters) -> String? {
        if case .summary = self {
            return parameters.walletName
        } else {
            return nil
        }
    }
}
