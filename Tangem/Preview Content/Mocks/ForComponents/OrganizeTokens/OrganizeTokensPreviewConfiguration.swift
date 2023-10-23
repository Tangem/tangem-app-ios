//
//  OrganizeTokensPreviewConfiguration.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensPreviewConfiguration {
    let name: String
    let groupingOption: UserTokensReorderingOptions.Grouping
    let sortingOption: UserTokensReorderingOptions.Sorting
}

// MARK: - CaseIterable protocol conformance

extension OrganizeTokensPreviewConfiguration: CaseIterable {
    static var allCases: [Self] {
        return [
            .init(
                name: "Non-grouped with manual sorting",
                groupingOption: .none,
                sortingOption: .dragAndDrop
            ),
            .init(
                name: "Grouped with manual sorting",
                groupingOption: .byBlockchainNetwork,
                sortingOption: .dragAndDrop
            ),
            .init(
                name: "Non-grouped with sorting by balance",
                groupingOption: .none,
                sortingOption: .byBalance
            ),
            .init(
                name: "Grouped with sorting by balance",
                groupingOption: .byBlockchainNetwork,
                sortingOption: .byBalance
            ),
        ]
    }
}
