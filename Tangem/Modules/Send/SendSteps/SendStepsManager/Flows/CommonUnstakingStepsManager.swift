//
//  CommonUnstakingStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonUnstakingStepsManager {
    private let state: AnyPublisher<UnstakingModel.State, Never>

    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var action: SendFlowActionType = .stake
    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []
    private weak var output: SendStepsManagerOutput?

    init(
        state: AnyPublisher<UnstakingModel.State, Never>,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.state = state
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [summaryStep]
        bind()
    }

    private func bind() {
        state.map { state in
            switch state {
            case .unstaking: .unstake
            case .withdraw: .withdraw
            }
        }
        .assign(to: \.action, on: self, ownership: .weak)
        .store(in: &bag)
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
    var initialState: SendStepsManagerViewState {
        .init(step: summaryStep, action: .action(.unstake), backButtonVisible: false)
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
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
