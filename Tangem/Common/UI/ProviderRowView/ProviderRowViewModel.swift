//
//  ProviderRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct ProviderRowViewModel: Identifiable {
    var id: Int { provider.hashValue }

    let provider: Provider
    let titleFormat: TitleFormat

    var providerTitle: Title {
        switch titleFormat {
        case .prefixAndName:
            let text = Localization.expressByProviderPlaceholder(provider.name)

            let attributeContainer = AttributeContainer()
            var attributedString = AttributedString(text, attributes: attributeContainer)
            attributedString.font = Fonts.Regular.footnote
            attributedString.foregroundColor = Colors.Text.tertiary

            if let range = attributedString.range(of: provider.name) {
                attributedString[range].foregroundColor = Colors.Text.primary1
            }

            return .attributed(attributedString)

        case .name:
            return .text(provider.name)
        }
    }

    let isDisabled: Bool
    let badge: Badge?
    let subtitles: [Subtitle]
    let detailsType: DetailsType?
    let tapAction: (() -> Void)?

    init(
        provider: Provider,
        titleFormat: TitleFormat,
        isDisabled: Bool,
        badge: Badge?,
        subtitles: [Subtitle],
        detailsType: DetailsType?,
        tapAction: (() -> Void)? = nil
    ) {
        self.provider = provider
        self.titleFormat = titleFormat
        self.isDisabled = isDisabled
        self.badge = badge
        self.subtitles = subtitles
        self.detailsType = detailsType
        self.tapAction = tapAction
    }
}

extension ProviderRowViewModel {
    enum Title {
        case text(String)
        case attributed(AttributedString)
    }

    enum TitleFormat {
        case prefixAndName
        case name
    }

    struct Provider: Hashable {
        let id: String
        let iconURL: URL?
        let name: String
        let type: String
    }

    enum Badge: String, Hashable {
        case permissionNeeded
        case bestRate
    }

    enum Subtitle: Hashable, Identifiable {
        var id: Int { hashValue }

        case text(String)
        case percent(String, signType: ChangeSignType)
    }

    enum DetailsType: Hashable {
        case selected
        case chevron
    }
}
