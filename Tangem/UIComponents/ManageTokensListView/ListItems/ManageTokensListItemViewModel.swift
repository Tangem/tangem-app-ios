//
//  ManageTokensListItemViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 21/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class ManageTokensListItemViewModel: ObservableObject, Identifiable {
    @Published var atLeastOneTokenSelected: Bool
    @Published var isExpanded: Bool = false

    let id: UUID = .init()
    let coinId: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let items: [ManageTokensItemNetworkSelectorViewModel]

    private var selectionUpdateSubscription: AnyCancellable?
    private var expandedUpdateSubscription: AnyCancellable?

    private var isExpandedBinding: Binding<Bool>?

    init(coinId: String, imageURL: URL?, name: String, symbol: String, items: [ManageTokensItemNetworkSelectorViewModel]) {
        self.coinId = coinId
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.items = items
        atLeastOneTokenSelected = items.first(where: { $0.isSelected }) != nil
        bindToSelectionUpdates()
    }

    init(with model: CoinModel, items: [ManageTokensItemNetworkSelectorViewModel]) {
        coinId = model.id
        name = model.name
        symbol = model.symbol
        imageURL = IconURLBuilder().tokenIconURL(id: model.id, size: .large)
        self.items = items
        atLeastOneTokenSelected = items.first(where: { $0.isSelected }) != nil
        bindToSelectionUpdates()
        bindToExpandedUpdates()
    }

    func update(expanded binding: Binding<Bool>?) {
        isExpandedBinding = binding
        isExpanded = binding?.wrappedValue ?? false
    }

    func bindToSelectionUpdates() {
        selectionUpdateSubscription = items.map { $0.$isSelected }
            .combineLatest()
            .withWeakCaptureOf(self)
            .sink { viewModel, itemsIsSelectedValues in
                viewModel.atLeastOneTokenSelected = itemsIsSelectedValues.first(where: { $0 }) ?? false
            }
    }

    func bindToExpandedUpdates() {
        expandedUpdateSubscription = $isExpanded
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, value in
                viewModel.isExpandedBinding?.wrappedValue = value
            })
    }

    func hasContractAddress(_ contractAddress: String) -> Bool {
        items.contains { item in
            guard let tokenContractAddress = item.tokenItem.contractAddress else {
                return false
            }

            return tokenContractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
        }
    }
}

extension ManageTokensListItemViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManageTokensListItemViewModel, rhs: ManageTokensListItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
