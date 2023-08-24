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
    private let userTokenListManager: UserTokenListManager
    private let editingThrottleInterval: TimeInterval
    private let editedGroupingOption = PassthroughSubject<OrganizeTokensOptions.Grouping, Never>()
    private let editedSortingOption = PassthroughSubject<OrganizeTokensOptions.Sorting, Never>()

    init(
        userTokenListManager: UserTokenListManager,
        editingThrottleInterval: TimeInterval
    ) {
        self.userTokenListManager = userTokenListManager
        self.editingThrottleInterval = editingThrottleInterval
    }
}

// MARK: - OrganizeTokensOptionsProviding protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsProviding {
    var groupingOption: AnyPublisher<OrganizeTokensOptions.Grouping, Never> {
        let editedGroupingOption = editedGroupingOption
            .throttle(
                for: RunLoop.SchedulerTimeType.Stride(editingThrottleInterval),
                scheduler: RunLoop.main,
                latest: false
            )
            .eraseToAnyPublisher()

        let groupingOptionFromUserTokenList = userTokenListManager
            .userTokensListPublisher
            .prefix(untilOutputFrom: editedGroupingOption)
            .map { OrganizeTokensOptionsConverter().convert($0.grouping) }
            .eraseToAnyPublisher()

        return [
            editedGroupingOption,
            groupingOptionFromUserTokenList,
        ].merge()
    }

    var sortingOption: AnyPublisher<OrganizeTokensOptions.Sorting, Never> {
        let editedSortingOption = editedSortingOption
            .throttle(
                for: RunLoop.SchedulerTimeType.Stride(editingThrottleInterval),
                scheduler: RunLoop.main,
                latest: false
            )
            .eraseToAnyPublisher()

        let sortingOptionFromUserTokenList = userTokenListManager
            .userTokensListPublisher
            .prefix(untilOutputFrom: editedSortingOption)
            .map { OrganizeTokensOptionsConverter().convert($0.sorting) }
            .eraseToAnyPublisher()

        return [
            editedSortingOption,
            sortingOptionFromUserTokenList,
        ].merge()
    }
}

// MARK: - OrganizeTokensOptionsEditing protocol conformance

extension OrganizeTokensOptionsManager: OrganizeTokensOptionsEditing {
    func group(by groupingOption: OrganizeTokensOptions.Grouping) {
        editedGroupingOption.send(groupingOption)
    }

    func sort(by sortingOption: OrganizeTokensOptions.Sorting) {
        editedSortingOption.send(sortingOption)
    }

    func save(
        reorderedWalletModelIds: [WalletModel.ID]
    ) -> AnyPublisher<Void, Never> {
        return .just
            .withLatestFrom(groupingOption, sortingOption, userTokenListManager.userTokensListPublisher)
            .withWeakCaptureOf(self)
            .flatMapLatest { input in
                let (manager, (grouping, sorting, userTokenList)) = input

                return Deferred {
                    Future<Void, Never> { [userTokenListManager = manager.userTokenListManager] promise in
                        let converter = OrganizeTokensOptionsConverter()
                        let userTokensKeyedByIds = userTokenList.entries.keyedFirst(by: \.walletModelId)
                        let reorderedUserTokens = reorderedWalletModelIds.compactMap { userTokensKeyedByIds[$0] }

                        assert(reorderedUserTokens.count == userTokenList.entries.count, "Model inconsistency detected")

                        let editedList = StoredUserTokenList(
                            entries: reorderedUserTokens,
                            grouping: converter.convert(grouping),
                            sorting: converter.convert(sorting)
                        )

                        userTokenListManager.update(with: editedList)
                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
