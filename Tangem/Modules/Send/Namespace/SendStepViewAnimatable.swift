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
    case appearing(previousStep: SendStepType)
    case appeared
    case disappearing(nextStep: SendStepType)
    case disappeared
}
