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
import BigInt
import BlockchainSdk

protocol SendFeeViewModelInput {
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }

    var customFeePublisher: AnyPublisher<Fee?, Never> { get }

    var canIncludeFeeIntoAmount: Bool { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    func didSelectFeeOption(_ feeOption: FeeOption)
    func didChangeFeeInclusion(_ isFeeIncluded: Bool)
}

class SendFeeViewModel: ObservableObject {
    let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)

    weak var router: SendFeeRoutable?

    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var showCustomFeeFields: Bool = false
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false
    @Published private(set) var deselectedFeeViewsVisible: Bool = false

    var didProperlyDisappear = true

    private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

    @Published private var isFeeIncluded: Bool = false

    @Published private(set) var feeLevelsNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var customFeeNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var feeCoverageNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    private let notificationManager: SendNotificationManager
    private let input: SendFeeViewModelInput
    private let feeOptions: [FeeOption]
    private let walletInfo: SendWalletInfo
    private let customFeeService: CustomFeeService?
    private let customFeeInFiat = CurrentValueSubject<String?, Never>("")
    // Save this values to compare it when the focus changed and send analytics
    private var customFeeValue: Decimal?
    private var customFeeBeforeEditing: Decimal?
    private var bag: Set<AnyCancellable> = []

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var balanceConverter = BalanceConverter()

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(input: SendFeeViewModelInput, notificationManager: SendNotificationManager, customFeeService: CustomFeeService?, walletInfo: SendWalletInfo) {
        self.input = input
        self.notificationManager = notificationManager
        self.customFeeService = customFeeService
        self.walletInfo = walletInfo
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption

        if feeOptions.contains(.custom) {
            createCustomFeeModels()
        }

        feeRowViewModels = makeFeeRowViewModels([:])

        bind()
    }

    func onAppear() {
        let deselectedFeeViewAppearanceDelay = SendView.Constants.animationDuration / 3
        DispatchQueue.main.asyncAfter(deadline: .now() + deselectedFeeViewAppearanceDelay) {
            withAnimation(SendView.Constants.defaultAnimation) {
                self.deselectedFeeViewsVisible = true
            }
        }

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        } else {
            Analytics.log(.sendFeeScreenOpened)
        }
    }

    func onDisappear() {
        deselectedFeeViewsVisible = false
    }

    func openFeeExplanation() {
        router?.openFeeExplanation(url: feeExplanationUrl)
    }

    private func createCustomFeeModels() {
        guard let customFeeService else { return }

        let editableCustomFeeService = customFeeService as? EditableCustomFeeService
        let onCustomFeeFieldChange: ((Decimal?) -> Void)?
        if let editableCustomFeeService {
            onCustomFeeFieldChange = { [weak self] value in
                self?.customFeeValue = value
                editableCustomFeeService.setCustomFee(value: value)
            }
        } else {
            onCustomFeeFieldChange = nil
        }

        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: input.customFeePublisher.decimalPublisher,
            disabled: editableCustomFeeService == nil,
            fieldSuffix: walletInfo.feeCurrencySymbol,
            fractionDigits: walletInfo.feeFractionDigits,
            amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
            footer: customFeeService.customFeeDescription,
            onFieldChange: onCustomFeeFieldChange
        ) { [weak self] focused in
            self?.onCustomFeeChanged(focused)
        }

        customFeeModels = [customFeeModel] + customFeeService.inputFieldModels()
    }

    private func bind() {
        input.feeValues
            .withWeakCaptureOf(self)
            .sink { (self, feeValues) in
                self.feeRowViewModels = self.makeFeeRowViewModels(feeValues)
            }
            .store(in: &bag)

        input
            .customFeePublisher
            .withWeakCaptureOf(self)
            .map { (self, customFee) -> String? in
                guard
                    let customFee,
                    let feeCurrencyId = self.walletInfo.feeCurrencyId,
                    let fiatFee = self.balanceConverter.convertToFiat(value: customFee.amount.value, from: feeCurrencyId)
                else {
                    return nil
                }

                return self.balanceFormatter.formatFiatBalance(fiatFee)
            }
            .withWeakCaptureOf(self)
            .sink { (self, customFeeInFiat) in
                self.customFeeInFiat.send(customFeeInFiat)
            }
            .store(in: &bag)

        input.isFeeIncludedPublisher
            .assign(to: \.isFeeIncluded, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeLevels)
            .assign(to: \.feeLevelsNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .customFee)
            .assign(to: \.customFeeNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeIncluded)
            .assign(to: \.feeCoverageNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func makeFeeRowViewModels(_ feeValues: [FeeOption: LoadingValue<Fee>]) -> [FeeRowViewModel] {
        let formattedFeeValuePairs: [(FeeOption, LoadingValue<FormattedFeeComponents?>)] = feeValues.map { feeOption, feeValue in
            let result: LoadingValue<FormattedFeeComponents?>
            switch feeValue {
            case .loading:
                result = .loading
            case .loaded(let value):
                let formattedFeeComponents = self.feeFormatter.formattedFeeComponents(
                    fee: value.amount.value,
                    currencySymbol: walletInfo.feeCurrencySymbol,
                    currencyId: walletInfo.feeCurrencyId,
                    isFeeApproximate: walletInfo.isFeeApproximate
                )
                result = .loaded(formattedFeeComponents)
            case .failedToLoad(let error):
                result = .failedToLoad(error: error)
            }

            return (feeOption, result)
        }

        let formattedFeeValues = Dictionary(uniqueKeysWithValues: formattedFeeValuePairs)
        return feeOptions.map { option in
            let value = formattedFeeValues[option] ?? .failedToLoad(error: WalletError.failedToGetFee)

            return FeeRowViewModel(
                option: option,
                formattedFeeComponents: value,
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == option
                }, set: { root, newValue in
                    if newValue {
                        self.selectFeeOption(option)
                    }
                })
            )
        }
    }

    private func selectFeeOption(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

        selectedFeeOption = feeOption
        input.didSelectFeeOption(feeOption)
        showCustomFeeFields = feeOption == .custom
    }

    private func onCustomFeeChanged(_ focused: Bool) {
        if focused {
            customFeeBeforeEditing = customFeeValue
        } else {
            if customFeeValue != customFeeBeforeEditing {
                Analytics.log(.sendPriorityFeeInserted)
            }

            customFeeBeforeEditing = nil
        }
    }
}

extension SendFeeViewModel: AuxiliaryViewAnimatable {}

// MARK: - private extensions

private extension AnyPublisher where Output == Fee?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.amount.value }.eraseToAnyPublisher()
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.decimal }.eraseToAnyPublisher()
    }
}
