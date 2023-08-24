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
            .userTokenList
            .prefix(untilOutputFrom: editedGroupingOption)
            .map { OrganizeTokensOptionsConverter().convert($0.group) }
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
            .userTokenList
            .prefix(untilOutputFrom: editedSortingOption)
            .map { OrganizeTokensOptionsConverter().convert($0.sort) }
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

    func save() -> AnyPublisher<Void, Never> {
        return .just
            .withLatestFrom(groupingOption, sortingOption, userTokenListManager.userTokenList)
            .withWeakCaptureOf(self)
            .flatMapLatest { input in
                let (manager, (grouping, sorting, userTokenList)) = input

                return Deferred {
                    Future<Void, Never> { [userTokenListManager = manager.userTokenListManager] promise in
                        let converter = OrganizeTokensOptionsConverter()
                        var updatedUserTokenList = userTokenList
                        updatedUserTokenList.group = converter.convert(grouping)
                        updatedUserTokenList.sort = converter.convert(sorting)
//                        userTokenListManager.update(with: updatedUserTokenList) // TODO: Andrey Fedorov - More robust updating logic with background work and retries support (IOS-4152)
                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}
