//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendSummaryViewModel: ObservableObject, Identifiable {
    @Published var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?

    @Published var sendDestinationCompactViewModelId: UUID = .init()
    @Published var sendAmountCompactViewModelId: UUID = .init()
    @Published var stakingValidatorsCompactViewModelId: UUID = .init()
    @Published var sendFeeCompactViewModelId: UUID = .init()

    @Published var destinationExpanding = false
    @Published var amountExpanding = false
    @Published var validatorExpanding = false
    @Published var feeExpanding = false

    @Published var destinationEditMode = false
    @Published var amountEditMode = false
    @Published var validatorEditMode = false
    @Published var feeEditMode = false

    @Published var destinationVisible = true
    @Published var amountVisible = true
    @Published var validatorVisible = true
    @Published var feeVisible = true

    @Published var showHint = false
    @Published var notificationInputs: [NotificationViewInput] = []

    @Published var transactionDescription: String?
    @Published var transactionDescriptionIsVisible: Bool = false

    var destinationCompactViewType: SendCompactViewEditableType {
        switch editableType {
        case .disable: .disabled
        case .editable: .enabled(action: userDidTapDestination)
        case .noEditable: .enabled()
        }
    }

    var amountCompactViewType: SendCompactViewEditableType {
        switch editableType {
        case .disable: .disabled
        case .editable: .enabled(action: userDidTapAmount)
        case .noEditable: .enabled()
        }
    }

    private let tokenItem: TokenItem
    private let editableType: EditableType
    private let interactor: SendSummaryInteractor
    private let notificationManager: NotificationManager
    private let actionType: SendFlowActionType
    weak var router: SendSummaryStepsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        interactor: SendSummaryInteractor,
        notificationManager: NotificationManager,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) {
        editableType = settings.editableType
        tokenItem = settings.tokenItem
        actionType = settings.actionType

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel

        bind()
    }

    func onAppear() {
        destinationVisible = true
        amountVisible = true
        validatorVisible = true
        feeVisible = true
        transactionDescriptionIsVisible = true

        if actionType == .send {
            Analytics.log(.sendConfirmScreenOpened)
        } else {
            Analytics.log(
                event: .stakingConfirmationScreenOpened,
                params: [
                    .validator: stakingValidatorsCompactViewModel?.selectedValidator?.address ?? "",
                    .action: actionType.stakingAnalyticsAction?.rawValue ?? "",
                ]
            )
        }

        // For the sake of simplicity we're assuming that notifications aren't going to be created after the screen has been displayed
        if notificationInputs.isEmpty, !AppSettings.shared.userDidTapSendScreenSummary {
            withAnimation(SendTransitionService.Constants.defaultAnimation.delay(SendTransitionService.Constants.animationDuration * 2)) {
                self.showHint = true
            }
        }
    }

    func onDisappear() {}

    func userDidTapDestination() {
        destinationExpanding = true
        amountExpanding = false
        validatorExpanding = false
        feeExpanding = false

        didTapSummary()
        router?.summaryStepRequestEditDestination()
    }

    func userDidTapAmount() {
        destinationExpanding = false
        amountExpanding = true
        validatorExpanding = false
        feeExpanding = false

        didTapSummary()
        router?.summaryStepRequestEditAmount()
    }

    func userDidTapValidator() {
        destinationExpanding = false
        amountExpanding = false
        validatorExpanding = true
        feeExpanding = false

        didTapSummary()

        Analytics.log(
            event: .stakingButtonValidator,
            params: [.source: Analytics.ParameterValue.stakeSourceConfirmation.rawValue]
        )

        router?.summaryStepRequestEditValidators()
    }

    func userDidTapFee() {
        destinationExpanding = false
        amountExpanding = false
        validatorExpanding = false
        feeExpanding = true

        didTapSummary()
        router?.summaryStepRequestEditFee()
    }

    private func didTapSummary() {
        AppSettings.shared.userDidTapSendScreenSummary = true
        showHint = false
    }

    private func bind() {
        interactor
            .transactionDescription
            .receive(on: DispatchQueue.main)
            .assign(to: \.transactionDescription, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, notificationInputs in
                viewModel.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension SendSummaryViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.destination(_)):
            destinationEditMode = true
            amountEditMode = false
            validatorEditMode = false
            feeEditMode = false

            destinationVisible = false
            amountVisible = true
            validatorVisible = true
            feeVisible = true

            showHint = false
            transactionDescriptionIsVisible = false

        case .appearing(.amount(_)):
            destinationEditMode = false
            amountEditMode = true
            validatorEditMode = false
            feeEditMode = false

            destinationVisible = true
            amountVisible = false
            validatorVisible = true
            feeVisible = true

            showHint = false
            transactionDescriptionIsVisible = false

        case .appearing(.validators(_)):
            destinationEditMode = false
            amountEditMode = false
            validatorEditMode = true
            feeEditMode = false

            destinationVisible = true
            amountVisible = true
            validatorVisible = false
            feeVisible = true

            showHint = false
            transactionDescriptionIsVisible = false
        case .appearing(.fee(_)):
            destinationEditMode = false
            amountEditMode = false
            validatorEditMode = false
            feeEditMode = true

            destinationVisible = true
            amountVisible = true
            validatorVisible = true
            feeVisible = false

            showHint = false
            transactionDescriptionIsVisible = false
        default:
            // Do not update ids
            return
        }

        // Force to update the compact view transition
        sendDestinationCompactViewModelId = .init()
        sendAmountCompactViewModelId = .init()
        stakingValidatorsCompactViewModelId = .init()
        sendFeeCompactViewModelId = .init()
    }
}

extension SendSummaryViewModel {
    struct Settings {
        let tokenItem: TokenItem
        let editableType: EditableType
        let actionType: SendFlowActionType
    }

    enum EditableType: Hashable {
        case disable
        case editable
        case noEditable
    }
}
