//
//  SendGeometryEffectNames.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - All names

struct SendGeometryEffectNames {}

// MARK: - SendDestinationViewGeometryEffectNames

extension SendGeometryEffectNames: SendDestinationViewGeometryEffectNames {
    var destinationContainer: String { "destinationContainer" }

    var addressContainer: String { "addressContainer" }
    var addressTitle: String { "addressTitle" }
    var addressIcon: String { "addressIcon" }
    var addressText: String { "addressText" }
    var addressClearButton: String { "addressClearButton" }
    var addressBackground: String { "addressBackground" }

    var addressAdditionalFieldContainer: String { "addressAdditionalFieldContainer" }
    var addressAdditionalFieldTitle: String { "addressAdditionalFieldTitle" }
    var addressAdditionalFieldIcon: String { "addressAdditionalFieldIcon" }
    var addressAdditionalFieldText: String { "addressAdditionalFieldText" }
    var addressAdditionalFieldClearButton: String { "addressAdditionalFieldClearButton" }
    var addressAdditionalFieldBackground: String { "addressAdditionalFieldBackground" }
}

// MARK: - SendAmountViewGeometryEffectNames

extension SendGeometryEffectNames: SendAmountViewGeometryEffectNames {
    var walletName: String { "walletName" }
    var walletBalance: String { "walletBalance" }
    var amountContainer: String { "amountContainer" }
    var tokenIcon: String { "tokenIcon" }
    var amountCryptoText: String { "amountCryptoText" }
    var amountFiatText: String { "amountFiatText" }
}

// MARK: - StakingValidatorsViewGeometryEffectNames

extension SendGeometryEffectNames: StakingValidatorsViewGeometryEffectNames {
    var validatorSectionHeaderTitle: String { "validatorSectionHeaderTitle" }
    var validatorContainer: String { "validatorContainer" }

    func validatorTitle(id: String) -> String { "validatorTitle_\(id)" }
    func validatorIcon(id: String) -> String { "validatorIcon_\(id)" }
    func validatorSubtitle(id: String) -> String { "validatorSubtitle_\(id)" }
    func validatorDetailsView(id: String) -> String { "validatorDetailsView_\(id)" }
}

// MARK: - SendFeeViewGeometryEffectNames

extension SendGeometryEffectNames: SendFeeViewGeometryEffectNames {
    var feeContainer: String { "feeContainer" }
    var feeTitle: String { "feeTitle" }

    func feeOption(feeOption: FeeOption) -> String { "feeOption_\(feeOption.rawValue)" }
    func feeAmount(feeOption: FeeOption) -> String { "feeAmount_\(feeOption.rawValue)" }
}

// MARK: - Destination step

protocol SendDestinationViewGeometryEffectNames {
    var destinationContainer: String { get }

    var addressContainer: String { get }
    var addressTitle: String { get }
    var addressIcon: String { get }
    var addressText: String { get }
    var addressClearButton: String { get }
    var addressBackground: String { get }

    var addressAdditionalFieldContainer: String { get }
    var addressAdditionalFieldTitle: String { get }
    var addressAdditionalFieldIcon: String { get }
    var addressAdditionalFieldText: String { get }
    var addressAdditionalFieldClearButton: String { get }
    var addressAdditionalFieldBackground: String { get }
}

// MARK: - Amount step

protocol SendAmountViewGeometryEffectNames {
    var walletName: String { get }
    var walletBalance: String { get }
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}

// MARK: - Validators step

protocol StakingValidatorsViewGeometryEffectNames {
    var validatorSectionHeaderTitle: String { get }
    var validatorContainer: String { get }

    func validatorTitle(id: String) -> String
    func validatorIcon(id: String) -> String
    func validatorSubtitle(id: String) -> String
    func validatorDetailsView(id: String) -> String
}

// MARK: - Fee step

protocol SendFeeViewGeometryEffectNames {
    var feeContainer: String { get }
    var feeTitle: String { get }
    func feeOption(feeOption: FeeOption) -> String
    func feeAmount(feeOption: FeeOption) -> String
}

// MARK: - Summary step

typealias SendSummaryViewGeometryEffectNames =
    SendDestinationViewGeometryEffectNames
        & SendAmountViewGeometryEffectNames
        & StakingValidatorsViewGeometryEffectNames
        & SendFeeViewGeometryEffectNames
