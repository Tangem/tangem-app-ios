//
//  ExpressProviderFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import UIKit

struct ExpressProviderFormatter {
    let balanceFormatter: BalanceFormatter

    func mapToRateSubtitle(
        state: ExpressProviderManagerState,
        senderCurrencyCode: String?,
        destinationCurrencyCode: String?,
        option: RateSubtitleFormattingOption
    ) -> ProviderRowViewModel.Subtitle {
        switch state {
        case .error(_, .none):
            return .text(AppConstants.dashSign)
        case .restriction(.tooSmallAmount(let minAmount), .none):
            guard let senderCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(minAmount, currencyCode: senderCurrencyCode)
            return .text(Localization.expressProviderMinAmount(formatted))
        case .restriction(.tooBigAmount(let maxAmount), .none):
            guard let senderCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(maxAmount, currencyCode: senderCurrencyCode)
            return .text(Localization.expressProviderMaxAmount(formatted))
        default:
            guard let quote = state.quote else {
                return .text(AppConstants.dashSign)
            }

            return mapToRateSubtitle(
                fromAmount: quote.fromAmount,
                toAmount: quote.expectAmount,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: option
            )
        }
    }

    func mapToRateSubtitle(
        fromAmount: Decimal,
        toAmount: Decimal,
        senderCurrencyCode: String?,
        destinationCurrencyCode: String?,
        option: RateSubtitleFormattingOption
    ) -> ProviderRowViewModel.Subtitle {
        switch option {
        case .exchangeRate:
            guard let senderCurrencyCode, let destinationCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let rate = toAmount / fromAmount
            let formattedSourceAmount = balanceFormatter.formatCryptoBalance(1, currencyCode: senderCurrencyCode)
            let formattedDestinationAmount = balanceFormatter.formatCryptoBalance(rate, currencyCode: destinationCurrencyCode)

            return .text("\(formattedSourceAmount) ≈ \(formattedDestinationAmount)")
        case .exchangeReceivedAmount:
            guard let destinationCurrencyCode else {
                return .text(CommonError.noData.localizedDescription)
            }

            let formatted = balanceFormatter.formatCryptoBalance(toAmount, currencyCode: destinationCurrencyCode)
            return .text(formatted)
        }
    }

    func mapToProvider(provider: ExpressProvider) -> ProviderRowViewModel.Provider {
        ProviderRowViewModel.Provider(
            id: provider.id,
            iconURL: provider.imageURL,
            name: provider.name,
            type: provider.type.title
        )
    }

    func mapToProvider(provider: ExpressPendingTransactionRecord.Provider) -> ProviderRowViewModel.Provider {
        ProviderRowViewModel.Provider(
            id: provider.id,
            iconURL: provider.iconURL,
            name: provider.name,
            type: provider.type.title
        )
    }

    func mapToLegalText(provider: ExpressProvider) -> AttributedString? {
        let tos = Localization.commonTermsOfUse
        let policy = Localization.commonPrivacyPolicy

        func makeBaseAttributedString(for text: String) -> AttributedString {
            var attributedString = AttributedString(text)
            attributedString.font = Fonts.Regular.footnote
            attributedString.foregroundColor = Colors.Text.tertiary
            return attributedString
        }

        func formatLink(in attributedString: inout AttributedString, textToSearch: String, url: URL) {
            guard let range = attributedString.range(of: textToSearch) else {
                return
            }

            attributedString[range].link = url
            attributedString[range].foregroundColor = Colors.Text.accent
        }

        if let termsOfUse = provider.termsOfUse, let privacyPolicy = provider.privacyPolicy {
            var attributedString = makeBaseAttributedString(for: Localization.expressLegalTwoPlaceholders(tos, policy))
            formatLink(in: &attributedString, textToSearch: tos, url: termsOfUse)
            formatLink(in: &attributedString, textToSearch: policy, url: privacyPolicy)
            return attributedString
        }

        if let termsOfUse = provider.termsOfUse {
            var attributedString = makeBaseAttributedString(for: Localization.expressLegalOnePlaceholder(tos))
            formatLink(in: &attributedString, textToSearch: tos, url: termsOfUse)
            return attributedString
        }

        if let privacyPolicy = provider.privacyPolicy {
            var attributedString = makeBaseAttributedString(for: Localization.expressLegalOnePlaceholder(policy))
            formatLink(in: &attributedString, textToSearch: policy, url: privacyPolicy)
            return attributedString
        }

        return nil
    }
}

private extension ExpressProviderType {
    var title: String {
        switch self {
        case .dex, .cex, .onramp, .unknown:
            return rawValue.uppercased()
        case .dexBridge:
            return "DEX/Bridge"
        }
    }
}

private extension ExpressPendingTransactionRecord.ProviderType {
    var title: String {
        switch self {
        case .dex, .cex, .unknown:
            return rawValue.uppercased()
        case .dexBridge:
            return "DEX/Bridge"
        }
    }
}

extension ExpressProviderFormatter {
    enum RateSubtitleFormattingOption {
        // How many destination's tokens user will get for the 1 token of source
        case exchangeRate

        // How many destination's tokens user will get at the end of swap
        case exchangeReceivedAmount
    }
}
