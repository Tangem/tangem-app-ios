//
//  ProviderRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ProviderRowViewModel {
    let provider: Provider
    let isDisabled: Bool
    let badge: Badge?
    let subtitles: [Subtitle]
    let detailsType: DetailsType?
    let tapAction: () -> Void
}

extension ProviderRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    static func == (lhs: ProviderRowViewModel, rhs: ProviderRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(provider)
        hasher.combine(isDisabled)
        hasher.combine(badge)
        hasher.combine(subtitles)
        hasher.combine(detailsType)
    }
}

extension ProviderRowViewModel {
    struct Provider: Hashable {
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
