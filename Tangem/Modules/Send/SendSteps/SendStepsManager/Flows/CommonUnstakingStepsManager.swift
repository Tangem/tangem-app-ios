//
//  CommonUnstakingStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class CommonUnstakingStepsManager {
    private let provider: UnstakingModelStateProvider

    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []
    private weak var output: SendStepsManagerOutput?

    init(
        provider: UnstakingModelStateProvider,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.provider = provider
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [summaryStep]
        bind()
    }

    private func bind() {
        provider.statePublisher
            .withWeakCaptureOf(self)
            .sink { manager, state in
                manager.updateAction(state: state)
            }
            .store(in: &bag)
    }

    private func updateAction(state: UnstakingModel.State) {
        switch state.action.type {
        case .unstake:
            output?.update(flowActionType: .unstake)
        case .pending(.withdraw):
            output?.update(flowActionType: .withdraw)
        case .pending(.claimRewards):
            output?.update(flowActionType: .claimRewards)
        case .pending(.restakeRewards):
            output?.update(flowActionType: .restakeRewards)
        case .stake:
            assertionFailure("Doesn't support in UnstakingFlow")
        }
    }

    private func next(step: SendStep) {
        stack.append(step)

        switch step.type {
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .amount, .destination, .fee, .summary, .validators:
            assertionFailure("There is no next step")
        }
    }
}

// MARK: - SendStepsManager

extension CommonUnstakingStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

    var initialFlowActionType: SendFlowActionType { .unstake }

    var initialState: SendStepsManagerViewState {
        .init(step: summaryStep, action: .action, backButtonVisible: false)
    }

    var shouldShowDismissAlert: Bool {
        return false
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output

        // Update action on UI to avoid animation jumping
        updateAction(state: provider.state)
    }

    func performBack() {
        assertionFailure("There's not back action in this flow")
    }

    func performNext() {
        assertionFailure("There's not next action in this flow")
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assertionFailure("There's not continue action in this flow")
    }
}
