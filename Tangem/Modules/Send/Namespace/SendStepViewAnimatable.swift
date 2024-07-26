//
//  SendStepViewAnimatable.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState)
}

enum SendStepVisibilityState: Hashable {
    case appearing(previousStep: SendStepType, isEditAction: Bool)
    case appeared

    case disappearing(nextStep: SendStepType, isEditAction: Bool)
    case disappeared

    var isEditAction: Bool {
        switch self {
        case .appearing(_, let isEditAction), .disappearing(_, let isEditAction):
            return isEditAction
        default:
            return false
        }
    }
}
