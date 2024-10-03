//
//  FakeOrganizeTokensOptionsManager.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class FakeOrganizeTokensOptionsManager {
    private let _groupingOption: CurrentValueSubject<UserTokensReorderingOptions.Grouping, Never>
    private let _sortingOption: CurrentValueSubject<UserTokensReorderingOptions.Sorting, Never>

    init(
        initialGroupingOption groupingOption: UserTokensReorderingOptions.Grouping,
        initialSortingOption sortingOption: UserTokensReorderingOptions.Sorting
    ) {
        _groupingOption = .init(groupingOption)
        _sortingOption = .init(sortingOption)
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension FakeOrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        return _groupingOption.eraseToAnyPublisher()
    }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        return _sortingOption.eraseToAnyPublisher()
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension FakeOrganizeTokensOptionsManager: OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping) {
        _groupingOption.send(groupingOption)
    }

    func sort(by sortingOption: UserTokensReorderingOptions.Sorting) {
        _sortingOption.send(sortingOption)
    }

    func save(reorderedWalletModelIds: [WalletModel.ID], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never> {
        return .just
    }
}
