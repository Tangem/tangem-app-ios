//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import struct BlockchainSdk.Fee

class SendFeeViewModel: ObservableObject, Identifiable {
    @Published private(set) var selectedFeeOption: FeeOption?
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

    @Published private(set) var auxiliaryViewsVisible: Bool = true

    @Published private(set) var networkFeeUnreachableNotificationViewInput: NotificationViewInput?

    var feeSelectorFooterText: String {
        Localization.commonFeeSelectorFooter(
            "[\(Localization.commonReadMore)](\(feeExplanationUrl.absoluteString))"
        )
    }

    private let feeTokenItem: TokenItem
    private let interactor: SendFeeInteractor
    private let notificationManager: NotificationManager

    private weak var router: SendFeeRoutable?

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    private var bag: Set<AnyCancellable> = []

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(
        settings: Settings,
        interactor: SendFeeInteractor,
        notificationManager: NotificationManager,
        router: SendFeeRoutable
    ) {
        feeTokenItem = settings.feeTokenItem

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.router = router

        bind()
    }

    func onAppear() {
        auxiliaryViewsVisible = true
    }

    func openFeeExplanation() {
        router?.openFeeExplanation(url: feeExplanationUrl)
    }

    private func bind() {
        interactor.feesPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, values in
                viewModel.updateViewModels(values: values)
            }
            .store(in: &bag)

        interactor.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.updateSelectedOption(selectedFee: selectedFee)
            }
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .map { notifications in
                notifications.first { input in
                    guard case .networkFeeUnreachable = input.settings.event as? SendNotificationEvent else {
                        return false
                    }

                    return true
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.networkFeeUnreachableNotificationViewInput, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateSelectedOption(selectedFee: SendFee?) {
        selectedFeeOption = selectedFee?.option

        let showCustomFeeFields = selectedFee?.option == .custom
        let models = showCustomFeeFields ? interactor.customFeeInputFieldModels : []
        if customFeeModels.count != models.count {
            customFeeModels = models
        }
    }

    private func updateCustomFee(fee: SendFee) {
        guard let customIndex = feeRowViewModels.firstIndex(where: { $0.option == .custom }) else {
            return
        }

        feeRowViewModels[customIndex] = mapToFeeRowViewModel(fee: fee)
        interactor.update(selectedFee: fee)
    }

    private func updateViewModels(values: [SendFee]) {
        feeRowViewModels = values.map { fee in
            mapToFeeRowViewModel(fee: fee)
        }
    }

    private func mapToFeeRowViewModel(fee: SendFee) -> FeeRowViewModel {
        let feeComponents = mapToFormattedFeeComponents(fee: fee.value)

        return FeeRowViewModel(
            option: fee.option,
            components: feeComponents,
            style: .selectable(
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == fee.option
                }, set: { root, newValue in
                    if newValue {
                        root.userDidSelected(fee: fee)
                    }
                })
            )
        )
    }

    private func mapToFormattedFeeComponents(fee: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch fee {
        case .loading:
            return .loading
        case .loaded(let value):
            let feeComponents = feeFormatter.formattedFeeComponents(fee: value.amount.value, tokenItem: feeTokenItem)
            return .loaded(feeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }

    private func userDidSelected(fee: SendFee) {
        if fee.option == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

        selectedFeeOption = fee.option
        interactor.update(selectedFee: fee)
    }
}

// MARK: - SendStepViewAnimatable

extension SendFeeViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.summary(_)):
            // Will be shown with animation
            auxiliaryViewsVisible = false
        case .disappearing(.summary(_)):
            auxiliaryViewsVisible = false
        default:
            break
        }
    }
}

extension SendFeeViewModel {
    struct Settings {
        let feeTokenItem: TokenItem
    }
}
