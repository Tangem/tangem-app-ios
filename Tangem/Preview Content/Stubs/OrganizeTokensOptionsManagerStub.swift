//
//  OrganizeTokensOptionsManagerStub.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class OrganizeTokensOptionsManagerStub {
    private let _groupingOption = PassthroughSubject<UserTokensReorderingOptions.Grouping, Never>()
    private let _sortingOption = PassthroughSubject<UserTokensReorderingOptions.Sorting, Never>()
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension OrganizeTokensOptionsManagerStub: OrganizeTokensOptionsProviding {
    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        return _groupingOption.eraseToAnyPublisher()
    }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        return _sortingOption.eraseToAnyPublisher()
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension OrganizeTokensOptionsManagerStub: OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping) {
        _groupingOption.send(groupingOption)
    }

    func sort(by sortingOption: UserTokensReorderingOptions.Sorting) {
        _sortingOption.send(sortingOption)
    }

    func save(reorderedWalletModelIds: [WalletModel.ID]) -> AnyPublisher<Void, Never> {
        return .just
    }
}
