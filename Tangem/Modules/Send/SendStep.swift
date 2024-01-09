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
    var name: String? {
        switch self {
        case .amount:
            return Localization.commonSend
        case .destination:
            return Localization.sendRecipient
        case .fee:
            return Localization.commonFeeSelectorTitle
        case .summary:
            return Localization.commonSend
        case .finish:
            return nil
        }
    }

    var hasNavigationButtons: Bool {
        switch self {
        case .amount, .destination, .fee:
            return true
        case .summary, .finish:
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
