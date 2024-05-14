//
//  SendSummarySectionViewModelFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendSummarySectionViewModelFactory {
    private let feeCurrencySymbol: String
    private let feeCurrencyId: String?
    private let isFeeApproximate: Bool
    private let currencyId: String?
    private let tokenIconInfo: TokenIconInfo

    private var feeFormatter: FeeFormatter {
        CommonFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter()
        )
    }

    init(feeCurrencySymbol: String, feeCurrencyId: String?, isFeeApproximate: Bool, currencyId: String?, tokenIconInfo: TokenIconInfo) {
        self.feeCurrencySymbol = feeCurrencySymbol
        self.feeCurrencyId = feeCurrencyId
        self.isFeeApproximate = isFeeApproximate
        self.currencyId = currencyId
        self.tokenIconInfo = tokenIconInfo
    }

    func makeDestinationViewTypes(address: String, additionalField: (SendAdditionalFields, String)?) -> [SendDestinationSummaryViewType] {
        var destinationViewTypes: [SendDestinationSummaryViewType] = []

        let addressCorners: UIRectCorner
        if let (additionalFieldType, additionalFieldValue) = additionalField,
           !additionalFieldValue.isEmpty {
            addressCorners = [.topLeft, .topRight]
            destinationViewTypes.append(.additionalField(type: additionalFieldType, value: additionalFieldValue))
        } else {
            addressCorners = .allCorners
        }

        destinationViewTypes.insert(.address(address: address, corners: addressCorners), at: 0)

        return destinationViewTypes
    }

    func makeAmountViewData(from amount: String?, amountAlternative: String?) -> SendAmountSummaryViewData? {
        guard let amount, let amountAlternative else { return nil }

        return SendAmountSummaryViewData(
            title: Localization.sendAmountLabel,
            amount: amount,
            amountAlternative: amountAlternative,
            tokenIconInfo: tokenIconInfo
        )
    }

    func makeFeeViewData(from value: LoadingValue<Fee>, feeOption: FeeOption) -> SendFeeSummaryViewModel? {
        let formattedFeeComponents = formattedFeeComponents(from: value)
        return SendFeeSummaryViewModel(
            title: Localization.commonNetworkFeeTitle,
            feeOption: feeOption,
            formattedFeeComponents: formattedFeeComponents
        )
    }

    func makeDeselectedFeeRowViewModel(from value: LoadingValue<Fee>, feeOption: FeeOption) -> FeeRowViewModel {
        return FeeRowViewModel(
            option: feeOption,
            formattedFeeComponents: formattedFeeComponents(from: value),
            isSelected: .init(get: {
                false
            }, set: { _ in

            })
        )
    }

    private func formattedFeeComponents(from feeValue: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents?> {
        switch feeValue {
        case .loading:
            return .loading
        case .loaded(let value):
            let formattedFeeComponents = feeFormatter.formattedFeeComponents(
                fee: value.amount.value,
                currencySymbol: feeCurrencySymbol,
                currencyId: feeCurrencyId,
                isFeeApproximate: isFeeApproximate
            )
            return .loaded(formattedFeeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }
}
