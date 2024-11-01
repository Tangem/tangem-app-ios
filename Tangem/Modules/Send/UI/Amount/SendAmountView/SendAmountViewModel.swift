//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendAmountViewModel: ObservableObject {
    // MARK: - ViewState

    let userWalletName: String
    let balance: String
    let tokenIconInfo: TokenIconInfo
    let currencyPickerData: SendCurrencyPickerData

    @Published var id: UUID = .init()

    @Published var auxiliaryViewsVisible: Bool = true
    @Published var isEditMode: Bool = false

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?

    @Published var bottomInfoText: BottomInfoTextType?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var amountType: SendAmountCalculationType = .crypto

    var isFiatCalculation: BindingValue<Bool> {
        .init(
            root: self,
            default: false,
            get: { $0.amountType == .fiat },
            set: { $0.amountType = $1 ? .fiat : .crypto }
        )
    }

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let interactor: SendAmountInteractor
    private let sendQRCodeService: SendQRCodeService?
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory
    private let actionType: SendFlowActionType

    private var bag: Set<AnyCancellable> = []

    init(
        initial: SendAmountViewModel.Settings,
        interactor: SendAmountInteractor,
        sendQRCodeService: SendQRCodeService?
    ) {
        tokenItem = initial.tokenItem
        userWalletName = initial.userWalletName
        balance = initial.balanceFormatted
        tokenIconInfo = initial.tokenIconInfo
        currencyPickerData = initial.currencyPickerData
        actionType = initial.actionType

        prefixSuffixOptionsFactory = .init()
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: initial.tokenItem.currencySymbol)
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: initial.tokenItem.decimalCount)

        self.interactor = interactor
        self.sendQRCodeService = sendQRCodeService

        bind()
    }

    func onAppear() {
        auxiliaryViewsVisible = true
    }

    func userDidTapMaxAmount() {
        switch actionType {
        case .send:
            Analytics.log(.sendMaxAmountTapped)
        case .stake:
            Analytics.log(.stakingButtonMax)
        default: break
        }
        let amount = interactor.updateToMaxAmount()
        decimalNumberTextFieldViewModel.update(value: amount?.main)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)
    }
}

// MARK: - Private

private extension SendAmountViewModel {
    func bind() {
        $amountType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel
            .valuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)

        interactor
            .infoTextPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.bottomInfoText, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .externalAmountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount?.main)
                viewModel.alternativeAmount = amount?.formatAlternative(
                    currencySymbol: viewModel.tokenItem.currencySymbol,
                    decimalCount: viewModel.tokenItem.decimalCount
                )
            }
            .store(in: &bag)

        sendQRCodeService?
            .qrCodeAmount
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.setExternalAmount(amount)
            }
            .store(in: &bag)
    }

    func setExternalAmount(_ amount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: amount)
        textFieldValueDidChanged(amount: amount)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        let amount = interactor.update(amount: amount)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)
    }

    func update(amountType: SendAmountCalculationType) {
        let amount = interactor.update(type: amountType)
        alternativeAmount = amount?.formatAlternative(currencySymbol: tokenItem.currencySymbol, decimalCount: tokenItem.decimalCount)

        switch amountType {
        case .crypto:
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            decimalNumberTextFieldViewModel.update(value: amount?.crypto)
        case .fiat:
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode)
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)
            decimalNumberTextFieldViewModel.update(value: amount?.fiat)
        }
    }
}

// MARK: - SendStepViewAnimatable

extension SendAmountViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.destination(_)):
            // Have to be always visible
            auxiliaryViewsVisible = true
            isEditMode = false
        case .appearing(.summary(_)):
            // Will be shown with animation
            auxiliaryViewsVisible = false
            isEditMode = true
        case .disappearing(.summary(_)):
            // Have to use this HACK to force re-render view with the new transition
            // Will look at it "if" later
            if !isEditMode {
                isEditMode = true
                id = UUID()
            } else {
                auxiliaryViewsVisible = false
            }

        default:
            break
        }
    }
}

extension SendAmountViewModel {
    struct Settings {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData
        let actionType: SendFlowActionType
    }

    enum BottomInfoTextType: Hashable {
        case info(String)
        case error(String)
    }
}
