//
//  OrganizeTokensOptionsManager.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class OrganizeTokensOptionsManager {
    private typealias OptionChange<T> = (currentValue: T, newValue: T?)

    private let userTokensReorderer: UserTokensReordering
    private let editedGroupingOption = CurrentValueSubject<UserTokensReorderingOptions.Grouping?, Never>(nil)
    private let editedSortingOption = CurrentValueSubject<UserTokensReorderingOptions.Sorting?, Never>(nil)

    private var groupingOptionToSave: AnyPublisher<OptionChange<UserTokensReorderingOptions.Grouping>, Never> {
        return editedGroupingOption
            .prepend(nil)
            .withLatestFrom(userTokensReorderer.groupingOption) { (currentValue: $1, newValue: $0) }
            .eraseToAnyPublisher()
    }

    private var sortingOptionToSave: AnyPublisher<OptionChange<UserTokensReorderingOptions.Sorting>, Never> {
        return editedSortingOption
            .prepend(nil)
            .withLatestFrom(userTokensReorderer.sortingOption) { (currentValue: $1, newValue: $0) }
            .eraseToAnyPublisher()
    }

    init(
        userTokensReorderer: UserTokensReordering
    ) {
        self.userTokensReorderer = userTokensReorderer
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> {
        let editedGroupingOption = editedGroupingOption
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let currentGroupingOption = userTokensReorderer
            .groupingOption
            .prefix(untilOutputFrom: editedGroupingOption)
            .eraseToAnyPublisher()

        return [
            editedGroupingOption,
            currentGroupingOption,
        ].merge()
    }

    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> {
        let editedSortingOption = editedSortingOption
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let currentSortingOption = userTokensReorderer
            .sortingOption
            .prefix(untilOutputFrom: editedSortingOption)
            .eraseToAnyPublisher()

        return [
            editedSortingOption,
            currentSortingOption,
        ].merge()
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping) {
        editedGroupingOption.send(groupingOption)
    }

    func sort(by sortingOption: UserTokensReorderingOptions.Sorting) {
        editedSortingOption.send(sortingOption)
    }

    func save(
        reorderedWalletModelIds: [WalletModel.ID]
    ) -> AnyPublisher<Void, Never> {
        return .just
            .withLatestFrom(userTokensReorderer.orderedWalletModelIds, groupingOptionToSave, sortingOptionToSave)
            .withWeakCaptureOf(self)
            .flatMapLatest { input in
                let (manager, (orderedWalletModelIds, groupingOption, sortingOption)) = input
                var reorderingActions: [UserTokensReorderingAction] = []

                if let newValue = groupingOption.newValue, newValue != groupingOption.currentValue {
                    reorderingActions.append(.setGroupingOption(option: newValue))
                }

                if let newValue = sortingOption.newValue, newValue != sortingOption.currentValue {
                    reorderingActions.append(.setSortingOption(option: newValue))
                }

                if reorderedWalletModelIds != orderedWalletModelIds {
                    reorderingActions.append(.reorder(reorderedWalletModelIds: reorderedWalletModelIds))
                }

                return manager.userTokensReorderer.reorder(reorderingActions)
            }
            .eraseToAnyPublisher()
    }
}
