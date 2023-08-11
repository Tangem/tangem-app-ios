//
//  OrganizeTokensHeaderViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class OrganizeTokensHeaderViewModel: ObservableObject {
    @Published var isSortByBalanceEnabled = false

    var sortByBalanceButtonTitle: String {
        return Localization.organizeTokensSortByBalance
    }

    @Published var isGroupingEnabled = false

    var groupingButtonTitle: String {
        return isGroupingEnabled
            ? Localization.organizeTokensUngroup
            : Localization.organizeTokensGroup
    }

    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    private let organizeTokensOptionsEditing: OrganizeTokensOptionsEditing

    private var bag: Set<AnyCancellable> = []

    init(
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding,
        organizeTokensOptionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
        self.organizeTokensOptionsEditing = organizeTokensOptionsEditing
    }

    func onViewAppear() {
        bind()
    }

    func toggleSortState() {
        organizeTokensOptionsEditing.sort(by: isSortByBalanceEnabled ? .dragAndDrop : .byBalance)
    }

    func toggleGroupState() {
        organizeTokensOptionsEditing.group(by: isGroupingEnabled ? .none : .byBlockchainNetwork)
    }

    private func bind() {
        organizeTokensOptionsProviding
            .groupingOption
            .map { groupingOption in
                switch groupingOption {
                case .none:
                    return false
                case .byBlockchainNetwork:
                    return true
                }
            }
            .assign(to: \.isGroupingEnabled, on: self, ownership: .weak)
            .store(in: &bag)

        organizeTokensOptionsProviding
            .sortingOption
            .map { sortingOption in
                switch sortingOption {
                case .dragAndDrop:
                    return false
                case .byBalance:
                    return true
                }
            }
            .assign(to: \.isSortByBalanceEnabled, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
