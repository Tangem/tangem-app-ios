//
//  StakingValidatorsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.xw
//

import Combine
import TangemStaking
import SwiftUI

final class StakingValidatorsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []
    @Published var selectedValidator: String = ""
    @Published var deselectedValidatorsIsVisible: Bool = false

    // MARK: - Dependencies

    private let interactor: StakingValidatorsInteractor

    private let stakingValidatorViewMapper = StakingValidatorViewMapper()
    private var bag: Set<AnyCancellable> = []

    init(interactor: StakingValidatorsInteractor) {
        self.interactor = interactor

        bind()
    }

    func onAppear() {
        let deselectedFeeViewAppearanceDelay = SendView.Constants.animationDuration / 3
        DispatchQueue.main.asyncAfter(deadline: .now() + deselectedFeeViewAppearanceDelay) {
            withAnimation(SendView.Constants.defaultAnimation) {
                self.deselectedValidatorsIsVisible = true
            }
        }
    }

    func onDisappear() {
        deselectedValidatorsIsVisible = false
    }
}

// MARK: - Private

private extension StakingValidatorsViewModel {
    func bind() {
        interactor
            .validatorsPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .map { viewModel, validators in
                // TODO: https://tangem.atlassian.net/browse/IOS-7105
                viewModel.selectedValidator = validators.first?.address ?? ""

                return validators.map {
                    viewModel.stakingValidatorViewMapper.mapToValidatorViewData(info: $0, detailsType: .checkmark)
                }
            }
            .assign(to: \.validators, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .selectedValidatorPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedValidator in
                viewModel.selectedValidator = selectedValidator.address
            }
            .store(in: &bag)

        $selectedValidator
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, validatorAddress in
                viewModel.interactor.userDidSelect(validatorAddress: validatorAddress)
            }
            .store(in: &bag)
    }
}

extension StakingValidatorsViewModel {
    struct Input {
        let validators: [ValidatorInfo]
    }
}
