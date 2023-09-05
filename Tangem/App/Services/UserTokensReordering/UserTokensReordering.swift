//
//  UserTokensReordering.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModel.ID], Never> { get }
    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { get }
    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { get }

    func reorder(_ reorderingActions: [UserTokensReorderingAction]) -> AnyPublisher<Void, Never>
}

// MARK: - Convenience extensions

extension UserTokensReordering {
    func reorder(_ reorderingActions: UserTokensReorderingAction...) -> AnyPublisher<Void, Never> {
        return reorder(reorderingActions.map { $0 })
    }
}
