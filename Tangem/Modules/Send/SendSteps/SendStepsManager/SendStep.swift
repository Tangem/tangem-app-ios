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
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { get }
    var sendStepViewAnimatable: any SendStepViewAnimatable { get }

    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool

    func willAppear(previous step: any SendStep)
    func willDisappear(next step: any SendStep)
}

extension SendStep {
    var subtitle: String? { .none }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .none }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        return true
    }

    func willAppear(previous step: any SendStep) {}
    func willDisappear(next step: any SendStep) {}
}
