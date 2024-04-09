//
//  SendStep.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum SendStep {
    case amount
    case destination
    case fee
    case summary
    case finish(model: SendFinishViewModel)
}

extension SendStep {
    struct Parameters {
        let currencyName: String
        let walletName: String
    }
}

extension SendStep {
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

    var opensKeyboardByDefault: Bool {
        switch self {
        case .amount:
            return true
        case .destination, .fee, .summary, .finish:
            return false
        }
    }
}

extension SendStep: Equatable {
    static func== (lhs: SendStep, rhs: SendStep) -> Bool {
        switch (lhs, rhs) {
        case (.amount, .amount):
            return true
        case (.destination, .destination):
            return true
        case (.fee, .fee):
            return true
        case (.summary, .summary):
            return true
        case (.finish, .finish):
            return true
        default:
            return false
        }
    }
}
